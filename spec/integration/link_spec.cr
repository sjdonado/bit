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

      parsed_response = Hash(String, Hash(String, String | Int64 | Array(Hash(String, String)))).from_json(response.body)
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
    it "should redirect to origin domain" do
      link = "https://test.com"
      test_user = create_test_user()

      test_link = create_test_link(test_user, link)
      serialized_link = App::Serializers::Link.new(test_link)

      get(serialized_link.refer, headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      response.headers["Location"].should eq(link)
    end

    it "should create a new click after redirect" do
      link = "https://sjdonado.com"
      test_user = create_test_user()

      test_link = create_test_link(test_user, link)
      serialized_link = App::Serializers::Link.new(test_link)

      get(serialized_link.refer, headers: HTTP::Headers{"User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0"})

      Fiber.yield # replace yield with sleep 5 to debug errors

      response.headers["Location"].should eq(link)

      updated_test_link = get_test_link(test_link.id)
      updated_test_link.clicks.size.should eq(test_link.clicks.size + 1)
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      get("https://localhost:4001/R4kj2")

      expected = {"error" => "Resource not found"}.to_json
      response.status_code.should eq(404)
      response.body.should eq(expected)
    end
  end

  describe "All" do
    it "should return all links" do
      links = ["https://google.com", "google.com", "google.com.co"]
      test_user = create_test_user()

      links.each do |link|
        create_test_link(test_user, link)
      end

      get("/api/links", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Array(Hash(String, String | Int64 | Array(Hash(String, String))))).from_json(response.body)
      parsed_response["data"][0]["origin"].should eq(links[0])
      parsed_response["data"][1]["origin"].should eq(links[1])
      parsed_response["data"][2]["origin"].should eq(links[2])
    end

    it "should return owned links only" do
      links = ["https://google.de", "google.de", "google.edu.co", "x.com"]
      test_user = create_test_user()

      links[0..2].each do |link|
        create_test_link(test_user, link)
      end

      test_other_user = create_test_user()
      create_test_link(test_other_user, links[3])

      get("/api/links", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Array(Hash(String, String | Int64 | Array(Hash(String, String))))).from_json(response.body)
      parsed_response["data"].size.should eq(3)
      parsed_response["data"][0]["origin"].should eq(links[0])
      parsed_response["data"][1]["origin"].should eq(links[1])
      parsed_response["data"][2]["origin"].should eq(links[2])
    end

    it "should return 401 - missing api key" do
      get "/api/links"

      expected = {"error" => "Unauthorized access"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Get" do
    it "should return the specified link with click details" do
      link = "https://bing.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      get("/api/links/#{test_link.id}", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Hash(String, String | Int64 | Array(Hash(String, String)))).from_json(response.body)
      parsed_response["data"]["origin"].should eq(link)
      parsed_response["data"]["clicks"].should be_a(Array(Hash(String, String)))
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      get("/api/links/1", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

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

      parsed_response = Hash(String, Hash(String, String | Int64 | Array(Hash(String, String)))).from_json(response.body)
      parsed_response["data"]["origin"].should eq(payload["url"])
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      payload = {"url" => "https://kagi.com.co"}
      put(
        "/api/links/1",
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

      delete("/api/links/1", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

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
