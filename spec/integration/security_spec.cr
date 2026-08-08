require "../spec_helper"

describe "API security and edge cases" do
  it "rejects invalid API keys" do
    ["invalid", ""].each do |api_key|
      get("/api/links", headers: HTTP::Headers{"X-Api-Key" => api_key})

      response.status_code.should eq(401)
      response.body.should eq({"error" => "Unauthorized access"}.to_json)
    end
  end

  it "rejects malformed IDs" do
    user = create_test_user()
    headers = HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => user.api_key.to_s}

    get("/api/links/not-a-number", headers: headers)
    response.status_code.should eq(400)

    get("/api/links/not-a-number/clicks", headers: headers)
    response.status_code.should eq(400)

    put("/api/links/not-a-number", headers: headers, body: {"url" => "https://example.com"}.to_json)
    response.status_code.should eq(400)

    delete("/api/links/not-a-number", headers: headers)
    response.status_code.should eq(400)
  end

  it "rejects malformed pagination" do
    user = create_test_user()
    headers = HTTP::Headers{"X-Api-Key" => user.api_key.to_s}

    ["0", "-1", "abc"].each do |limit|
      get("/api/links?limit=#{limit}", headers: headers)
      response.status_code.should eq(400)
    end

    ["abc", "0", "-1"].each do |cursor|
      get("/api/links?cursor=#{cursor}", headers: headers)
      response.status_code.should eq(400)
      response.body.should eq({"error" => "cursor must be a positive integer"}.to_json)
    end
  end

  it "rejects malformed and non-object JSON bodies" do
    user = create_test_user()
    headers = HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => user.api_key.to_s}

    ["{", "[]", "null"].each do |body|
      post("/api/links", headers: headers, body: body)
      response.status_code.should eq(400)
      response.body.should eq({"error" => "Invalid JSON body"}.to_json)
    end
  end

  it "isolates links and clicks between users" do
    owner = create_test_user()
    other_user = create_test_user()
    link = create_test_link(owner, "https://example.com/private")
    create_test_click(link)
    other_headers = HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => other_user.api_key.to_s}

    get("/api/links/#{link.id}", headers: other_headers)
    response.status_code.should eq(404)

    get("/api/links/#{link.id}/clicks", headers: other_headers)
    response.status_code.should eq(404)

    put("/api/links/#{link.id}", headers: other_headers, body: {"url" => "https://attacker.example.com"}.to_json)
    response.status_code.should eq(403)
    get_test_link(link.id.not_nil!).url.should eq("https://example.com/private")

    delete("/api/links/#{link.id}", headers: other_headers)
    response.status_code.should eq(403)
    get_test_link(link.id.not_nil!).url.should eq("https://example.com/private")
  end

  it "allows different users to shorten the same URL" do
    first_user = create_test_user()
    second_user = create_test_user()
    payload = {"url" => "https://example.com/shared"}.to_json

    post("/api/links", headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => first_user.api_key.to_s}, body: payload)
    response.status_code.should eq(201)
    first_id = JSON.parse(response.body)["data"]["id"].as_i64

    post("/api/links", headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => second_user.api_key.to_s}, body: payload)
    response.status_code.should eq(201)
    JSON.parse(response.body)["data"]["id"].as_i64.should_not eq(first_id)
  end

  it "validates link updates" do
    user = create_test_user()
    link = create_test_link(user, "https://example.com/original")
    create_test_link(user, "https://example.com/existing")
    headers = HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => user.api_key.to_s}

    put("/api/links/#{link.id}", headers: headers, body: ({} of String => String).to_json)
    response.status_code.should eq(400)

    put("/api/links/#{link.id}", headers: headers, body: {"url" => "invalid"}.to_json)
    response.status_code.should eq(422)

    put("/api/links/#{link.id}", headers: headers, body: {"url" => "https://example.com/existing"}.to_json)
    response.status_code.should eq(422)
    get_test_link(link.id.not_nil!).url.should eq("https://example.com/original")

    put("/api/links/#{link.id}", headers: headers, body: {"url" => "https://example.com/original"}.to_json)
    response.status_code.should eq(200)
    get_test_link(link.id.not_nil!).url.should eq("https://example.com/original")
  end

  it "validates click pagination" do
    user = create_test_user()
    link = create_test_link(user, "https://example.com/click-pagination")
    headers = HTTP::Headers{"X-Api-Key" => user.api_key.to_s}

    get("/api/links/#{link.id}/clicks?limit=0", headers: headers)
    response.status_code.should eq(400)

    ["invalid", "0", "-1"].each do |cursor|
      get("/api/links/#{link.id}/clicks?cursor=#{cursor}", headers: headers)
      response.status_code.should eq(400)
    end
  end

  it "records direct clicks without a user-agent" do
    user = create_test_user()
    link = create_test_link(user, "https://example.com/no-agent")

    get("/#{link.slug}")

    response.status_code.should eq(301)
    click = wait_for_clicks(link.id.not_nil!, 1).clicks.last
    click.user_agent.should be_nil
    click.referer.should eq("Direct")
  end

  it "prefers the referer over utm_source" do
    user = create_test_user()
    link = create_test_link(user, "https://example.com/source")

    get("/#{link.slug}?utm_source=campaign", headers: HTTP::Headers{
      "User-Agent" => "Mozilla/5.0 Firefox/127.0",
      "Referer"    => "https://referrer.example.com/path",
    })

    wait_for_clicks(link.id.not_nil!, 1).clicks.last.referer.should eq("referrer.example.com")
  end

  it "deletes associated clicks through the API" do
    user = create_test_user()
    link = create_test_link(user, "https://example.com/cascade")
    create_test_click(link)
    headers = HTTP::Headers{"X-Api-Key" => user.api_key.to_s}

    delete("/api/links/#{link.id}", headers: headers)

    response.status_code.should eq(204)
    App::Lib::Database.get(App::Models::Link, link.id).should be_nil
    query = App::Lib::Database::Query.where(link_id: link.id.not_nil!)
    App::Lib::Database.all(App::Models::Click, query).should be_empty
  end
end
