require "../spec_helper"

describe "App::Controllers::Ping" do
  it "should return pong" do
    get "/api/ping"

    expected = {"data" => "pong"}.to_json
    response.status_code.should eq(200)
    response.headers["Content-Type"].should eq("application/json")
    response.body.should eq(expected)
  end
end
