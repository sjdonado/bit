require "../spec_helper"

describe "App::Controllers::Ping" do
  it "should return pong" do
    get "/api/ping"

    expected = {"data" => "pong"}.to_json
    response.body.should eq(expected)
  end
end
