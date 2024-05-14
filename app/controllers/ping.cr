require "../lib/controller.cr"

module App::Controllers::Ping
  class Get < App::Lib::BaseController
    def call(env)
      response = {"pong" => "ok"}
      response.to_json
    end
  end
end
