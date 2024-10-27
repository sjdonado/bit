require "./controllers/**"

module App
  before_all do |env|
    env.response.headers["Access-Control-Allow-Origin"] = "*"
    env.response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    env.response.headers["Access-Control-Allow-Headers"] = "Content-Type, Accept, Origin, X-Api-Key"
  end

  after_all do |env|
    env.response.content_type = "application/json"
  end

  get "/api/ping" do |env|
    Controllers::Ping::Get.new.call(env)
  end

  get "/:slug" do |env|
    Controllers::Link::Index.new.call(env)
  end

  get "/api/links" do |env|
    Controllers::Link::All.new.call(env)
  end

  get "/api/links/:id" do |env|
    Controllers::Link::Get.new.call(env)
  end

  post "/api/links" do |env|
    Controllers::Link::Create.new.call(env)
  end

  put "/api/links/:id" do |env|
    Controllers::Link::Update.new.call(env)
  end

  delete "/api/links/:id" do |env|
    Controllers::Link::Delete.new.call(env)
  end
end
