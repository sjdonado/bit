require "./controllers/**"

require "kemal"

class CORSHandler < Kemal::Handler
  exclude ["/:slug"]

  def initialize(
    @allow_origin = "*",
    @allow_methods = "GET, POST, PUT, DELETE, OPTIONS",
    @allow_headers = "Content-Type, Accept, Origin, X-Api-Key"
  )
  end

  def call(context)
    return call_next(context) if exclude_match?(context)

    context.response.headers["Access-Control-Allow-Origin"] = @allow_origin
    context.response.headers["Access-Control-Allow-Methods"] = @allow_methods
    context.response.headers["Access-Control-Allow-Headers"] = @allow_headers

    # If this is a preflight OPTIONS request, we return immediately with 200
    if context.request.method == "OPTIONS"
      context.response.status_code = 200
      context.response.content_type = "text/plain"
      context.response.print("")
      return context
    end

    call_next(context)
  end
end

add_handler CORSHandler.new

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
