require "./controllers/**"

require "kemal"

use App::Middlewares::CORSHandler.new
use App::Middlewares::Auth.new

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

  {% for status in [400, 401, 403, 404, 405, 413, 422] %}
    error {{status}} do |env, ex|
      next ex.body if ex.is_a?(HttpException)
      {% if status == 404 %}
        NotFoundException.new(env).body
      {% else %}
        env.response.content_type = "application/json"
        { "error" => HTTP::Status.new({{status}}).description }.to_json
      {% end %}
    end
  {% end %}

  error 500 do |env|
    App::InternalServerErrorException.new(env).body
  end
end
