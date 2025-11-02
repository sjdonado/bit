require "../spec_helper"
require "../../app/models/*"

API_KEY = Random::Secure.urlsafe_base64

describe "App::Controllers::Link" do
  describe "Create" do
    it "should create link" do
      test_user = create_test_user()

      payload = {"url" => "https://kagi.com"}
      post(
        "/api/links",
        headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => test_user.api_key.to_s},
        body: payload.to_json
      )

      parsed_response = Hash(String, Hash(String, String | Int64 | Array(Hash(String, String | Int64)))).from_json(response.body)
      parsed_response["data"]["origin"].should eq(payload["url"])
    end

    it "should return existing link if url already exists" do
      test_user = create_test_user()

      payload = {"url" => "http://idonthavespotify.donado.co"}
      post(
        "/api/links",
        headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => test_user.api_key.to_s},
        body: payload.to_json
      )

      first_response = Hash(String, Hash(String, String | Int64 | Array(Hash(String, String)))).from_json(response.body)
      first_response["data"]["origin"].should eq(payload["url"])

      post(
        "/api/links",
        headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => test_user.api_key.to_s},
        body: payload.to_json
      )

      second_response = Hash(String, Hash(String, String | Int64 | Array(Hash(String, String)))).from_json(response.body)
      second_response["data"]["origin"].should eq(payload["url"])
      second_response["data"]["id"].should eq(first_response["data"]["id"])
    end

    it "should return 400 - url required field" do
      test_user = create_test_user()

      payload = {"test" => "https://kagi.com"}
      post(
        "/api/links",
        headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => test_user.api_key.to_s},
        body: payload.to_json
      )

      expected = {"error" => "url: Required field"}.to_json
      response.body.should eq(expected)
    end

    it "should return 400 - invalid url" do
      test_user = create_test_user()

      payload = {"url" => "test"}
      post(
        "/api/links",
        headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => test_user.api_key.to_s},
        body: payload.to_json
      )

      expected = {"errors" => {"url" => ["is invalid"]}}.to_json
      response.body.should eq(expected)
    end

    it "should return 401 - missing api key" do
      payload = {"url" => "https://kagi.com"}
      post("/api/links", headers: HTTP::Headers{"Content-Type" => "application/json"}, body: payload.to_json)

      expected = {"error" => "Unauthorized access"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Index" do
    it "should redirect to origin domain with forwarded headers" do
      link = "https://test.com"
      test_user = create_test_user()

      test_link = create_test_link(test_user, link)

      user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0"

      get("/#{test_link.slug}", headers: HTTP::Headers{
        "X-Api-Key" => test_user.api_key.to_s,
        "User-Agent" => user_agent
      })

      response.headers["Location"].should eq(link)
      response.headers["User-Agent"].should eq(user_agent)
      response.headers.has_key?("X-Forwarded-For").should be_true
    end

    it "should create a new click after redirect with proper information" do
      link = "https://sjdonado.com"
      test_user = create_test_user()

      test_link = create_test_link(test_user, link)

      user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0"
      referer = "https://example.com/page"

      get("/#{test_link.slug}", headers: HTTP::Headers{
        "User-Agent" => user_agent,
        "Referer" => referer
      })

      Fiber.yield # replace yield with sleep 5 to debug errors

      response.headers["Location"].should eq(link)

      # Verify that the click was recorded
      updated_test_link = get_test_link(test_link.id.not_nil!)
      updated_test_link.clicks.size.should eq(test_link.clicks.size + 1)

      # Verify click details
      latest_click = updated_test_link.clicks.last
      latest_click.user_agent.should eq(user_agent)
      latest_click.browser.should eq("Firefox")
      latest_click.os.should eq("Mac OS X")
      latest_click.referer.should eq("example.com") # Should extract host from the referer
    end

    it "should create a click with utm_source when no referer is provided" do
      link = "https://sjdonado.com"
      test_user = create_test_user()

      test_link = create_test_link(test_user, link)

      # Add utm_source parameter
      user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0"
      get("/#{test_link.slug}?utm_source=email_campaign", headers: HTTP::Headers{
        "User-Agent" => user_agent
      })

      sleep 0.2.seconds # Wait for async click creation

      updated_test_link = get_test_link(test_link.id.not_nil!)
      latest_click = updated_test_link.clicks.last
      latest_click.referer.should eq("email_campaign")
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      get("/R4kj2")

      expected = {"error" => "Resource not found"}.to_json
      response.status_code.should eq(404)
      response.body.should eq(expected)
    end
  end

  describe "All" do
    it "should return all links with pagination" do
      links = ["https://sjdonado.com", "sjdonado.com", "sjdonado.com.co"]
      test_user = create_test_user()

      links.each do |link|
        create_test_link(test_user, link)
      end

      get("/api/links", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)

      # Check that each link is in the response data
      origins = parsed_response["data"].as(Array).map { |link| link["origin"] }
      links.each do |link|
        origins.should contain(link)
      end

      parsed_response["pagination"].as(Hash)["has_more"].should be_false
    end

    it "should respect custom limit parameter" do
      test_user = create_test_user()

      5.times do |i|
        create_test_link(test_user, "https://example.com/#{i}")
      end

      get("/api/links?limit=2", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)
      parsed_response["data"].as(Array).size.should eq(2)
      parsed_response["pagination"].as(Hash)["has_more"].should be_true
      parsed_response["pagination"].as(Hash)["next"].should_not be_nil
    end

    it "should support cursor-based pagination" do
      test_user = create_test_user()

      5.times do |i|
        create_test_link(test_user, "https://example.com/#{i}")
      end

      # Get first page
      get("/api/links?limit=2", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})
      first_page = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)
      cursor = first_page["pagination"].as(Hash)["next"]

      # Get second page using cursor
      get("/api/links?limit=2&cursor=#{cursor}", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})
      second_page = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)

      # Ensure different links are returned
      first_page_ids = first_page["data"].as(Array).map { |link| link["id"] }
      second_page_ids = second_page["data"].as(Array).map { |link| link["id"] }

      # Check that no IDs from first page appear in second page
      (first_page_ids & second_page_ids).empty?.should be_true
    end

    it "should return owned links only" do
      links = ["https://donado.co", "donado.co", "uninorte.edu.co", "kagi.com"]
      test_user = create_test_user()

      links[0..2].each do |link|
        create_test_link(test_user, link)
      end

      test_other_user = create_test_user()
      create_test_link(test_other_user, links[3])

      get("/api/links", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)
      parsed_response["data"].as(Array).size.should eq(3)

      origins = parsed_response["data"].as(Array).map { |link| link["origin"] }
      links[0..2].each do |link|
        origins.should contain(link)
      end
      origins.should_not contain(links[3])
    end

    it "should return 401 - missing api key" do
      get "/api/links"

      expected = {"error" => "Unauthorized access"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Get" do
    it "should return the specified link with limited click details" do
      link = "https://bing.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      110.times do
        create_test_click(test_link)
      end

      get("/api/links/#{test_link.id}", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Hash(String, String | Int64 | Array(Hash(String, String | Int64)))).from_json(response.body)
      parsed_response["data"]["origin"].should eq(link)
      parsed_response["data"]["clicks"].as(Array).size.should eq(100)
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      get("/api/links/999999", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      expected = {"error" => "Resource not found"}.to_json
      response.status_code.should eq(404)
      response.body.should eq(expected)
    end

    it "should return 401 - missing api key" do
      get "/api/links/1"

      expected = {"error" => "Unauthorized access"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Clicks" do
    it "should return paginated clicks for a link" do
      link = "https://example.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      5.times do
        create_test_click(test_link)
      end

      get("/api/links/#{test_link.id}/clicks", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)
      parsed_response["data"].as(Array).size.should eq(5)
      parsed_response["pagination"].as(Hash)["has_more"].should be_false
    end

    it "should respect limit parameter" do
      link = "https://example.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      10.times do
        create_test_click(test_link)
      end

      get("/api/links/#{test_link.id}/clicks?limit=3", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)
      parsed_response["data"].as(Array).size.should eq(3)
      parsed_response["pagination"].as(Hash)["has_more"].should be_true
      parsed_response["pagination"].as(Hash)["next"].should_not be_nil
    end

    it "should support cursor-based pagination" do
      link = "https://example.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      10.times do
        create_test_click(test_link)
      end

      # Get first page
      get("/api/links/#{test_link.id}/clicks?limit=3", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})
      first_page = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)
      cursor = first_page["pagination"].as(Hash)["next"]

      # Get second page using cursor
      get("/api/links/#{test_link.id}/clicks?limit=3&cursor=#{cursor}", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})
      second_page = Hash(String, Array(Hash(String, String | Int64)) | Hash(String, Bool | String? | Int64?)).from_json(response.body)

      # Ensure different clicks are returned
      first_page_ids = first_page["data"].as(Array).map { |click| click["id"] }
      second_page_ids = second_page["data"].as(Array).map { |click| click["id"] }

      # Check that no IDs from first page appear in second page
      (first_page_ids & second_page_ids).empty?.should be_true
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      get("/api/links/999999/clicks", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      expected = {"error" => "Resource not found"}.to_json
      response.status_code.should eq(404)
      response.body.should eq(expected)
    end

    it "should return 401 - missing api key" do
      get("/api/links/1/clicks")

      expected = {"error" => "Unauthorized access"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Update" do
    it "should update link url" do
      link = "https://github.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      payload = {"url" => "https://github.com.co"}
      put(
        "/api/links/#{test_link.id}",
        headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => test_user.api_key.to_s},
        body: payload.to_json
      )

      parsed_response = Hash(String, Hash(String, String | Int64 | Array(Hash(String, String | Int64)))).from_json(response.body)
      parsed_response["data"]["origin"].should eq(payload["url"])
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      payload = {"url" => "https://kagi.com.co"}
      put(
        "/api/links/999999",
        headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => test_user.api_key.to_s},
        body: payload.to_json
      )

      expected = {"error" => "Resource not found"}.to_json
      response.status_code.should eq(404)
      response.body.should eq(expected)
    end

    it "should return 401 - missing api key" do
      payload = {"url" => "https://kagi.com.co"}
      put(
        "/api/links/1",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
        body: payload.to_json
      )

      expected = {"error" => "Unauthorized access"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Delete" do
    it "should delete link url" do
      link = "https://news.ycombinator.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      delete("/api/links/#{test_link.id}", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      response.status_code.should eq(204)
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      delete("/api/links/999999", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      expected = {"error" => "Resource not found"}.to_json
      response.status_code.should eq(404)
      response.body.should eq(expected)
    end

    it "should return 401 - missing api key" do
      delete "/api/links/1"

      expected = {"error" => "Unauthorized access"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end
end
