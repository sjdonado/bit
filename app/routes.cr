require "./controllers/**"

require "kemal"

add_handler App::Middlewares::CORSHandler.new
add_handler App::Middlewares::Auth.new

module App
  get "/:slug", &App::Controllers::ClickController.redirect_handler

  # Namespace /api
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

  error 500 do |env|
    App::InternalServerErrorException.new(env)
    ""
  end
end
