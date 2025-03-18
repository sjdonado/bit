require "./controllers/**"

module App
  # CORS handling middleware
  before_all do |env|
    if env.request.path.starts_with?("/api/")
      env.response.headers["Access-Control-Allow-Origin"] = "*"
      env.response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
      env.response.headers["Access-Control-Allow-Headers"] = "Content-Type, Accept, Origin, X-Api-Key"
    end
  end

  # Error handling middleware
  error 404 do |env|
    {error: "Not Found"}.to_json
  end
  error 500 do |env|
    {error: "Internal Server Error"}.to_json
  end

  get "/:slug" do |env|
    Controllers::LinkController.new(env).redirect
  end

  # namespace /api
  get "/api/ping" do |env|
    Controllers::PingController.new(env).ping
  end

  get "/api/links" do |env|
    Controllers::LinkController.new(env).list_all
  end

  get "/api/links/:id" do |env|
    Controllers::LinkController.new(env).get
  end

  get "/api/links/:id/clicks" do |env|
    Controllers::LinkController.new(env).list_clicks
  end

  post "/api/links" do |env|
    Controllers::LinkController.new(env).create
  end

  put "/api/links/:id" do |env|
    Controllers::LinkController.new(env).update
  end

  delete "/api/links/:id" do |env|
    Controllers::LinkController.new(env).delete
  end
end
