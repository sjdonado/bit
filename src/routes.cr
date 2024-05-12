require "./controllers/**"

module App
  before_all do |env|
    env.response.content_type = "application/json"
  end

  get "/api/ping" do |env|
    Controllers::Ping::Get.new.call(env)
  end

  get "/:slug" do |env|
    Controllers::Link::Index.new.call(env)
  end

  post "/api/links" do |env|
    Controllers::Link::Create.new.call(env)
  end
end
