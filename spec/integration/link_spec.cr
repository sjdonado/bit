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

      parsed_response = Hash(String, Hash(String, String | Int64)).from_json(response.body)
      parsed_response["data"]["origin"].should eq(payload["url"])
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

      expected = {"error" => "Unauthorized"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Index" do
    it "should redirect to origin domain" do
      link = "https://kagi.com"
      test_user = create_test_user()

      test_link = create_test_link(test_user, link)
      serialized_link = App::Serializers::Link.new(test_link)

      get(serialized_link.refer, headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      response.headers["Location"].should eq(link)
    end

    it "should increase click counter after redirect" do
      link = "https://kagi.com"
      test_user = create_test_user()

      test_link = create_test_link(test_user, link)
      serialized_link = App::Serializers::Link.new(test_link)

      get(serialized_link.refer, headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})
      Fiber.yield

      response.headers["Location"].should eq(link)

      updated_test_link = get_test_link(test_link.id)
      updated_test_link.click_counter.should eq(1)
    end

    it "should return 404 - link does not exist" do
      link = "https://kagi.com"
      test_user = create_test_user()

      test_link = create_test_link(test_user, link)
      serialized_link = App::Serializers::Link.new(test_link)

      delete_test_link(test_link.id)

      get(serialized_link.refer, headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      expected = {"error" => "Not Found"}.to_json
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

      parsed_response = Hash(String, Array(Hash(String, String | Int64))).from_json(response.body)
      parsed_response["data"][0]["origin"].should eq(links[0])
      parsed_response["data"][1]["origin"].should eq(links[1])
      parsed_response["data"][2]["origin"].should eq(links[2])
    end

    it "should return owned links only" do
      links = ["https://google.com", "google.com", "google.com.co", "kagi.com"]
      test_user = create_test_user()

      links[0..2].each do |link|
        create_test_link(test_user, link)
      end

      test_other_user = create_test_user()
      create_test_link(test_other_user, links[3])

      get("/api/links", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      parsed_response = Hash(String, Array(Hash(String, String | Int64))).from_json(response.body)
      parsed_response["data"].size.should eq(3)
      parsed_response["data"][0]["origin"].should eq(links[0])
      parsed_response["data"][1]["origin"].should eq(links[1])
      parsed_response["data"][2]["origin"].should eq(links[2])
    end

    it "should return 401 - missing api key" do
      get "/api/links"

      expected = {"error" => "Unauthorized"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Update" do
    it "should update link url" do
      link = "https://kagi.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      payload = {"url" => "https://kagi.com.co"}
      put(
        "/api/links/#{test_link.id}",
        headers: HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => test_user.api_key.to_s},
        body: payload.to_json
      )

      parsed_response = Hash(String, Hash(String, String | Int64)).from_json(response.body)
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

      expected = {"error" => "Not Found"}.to_json
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

      expected = {"error" => "Unauthorized"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end

  describe "Delete" do
    it "should delete link url" do
      link = "https://kagi.com"
      test_user = create_test_user()
      test_link = create_test_link(test_user, link)

      delete("/api/links/#{test_link.id}", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      response.status_code.should eq(204)
    end

    it "should return 404 - link does not exist" do
      test_user = create_test_user()

      delete("/api/links/1", headers: HTTP::Headers{"X-Api-Key" => test_user.api_key.to_s})

      expected = {"error" => "Not Found"}.to_json
      response.status_code.should eq(404)
      response.body.should eq(expected)
    end

    it "should return 401 - missing api key" do
      delete "/api/links/1"

      expected = {"error" => "Unauthorized"}.to_json
      response.status_code.should eq(401)
      response.body.should eq(expected)
    end
  end
end
