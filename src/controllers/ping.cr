require "../lib/controller.cr"

module Pa::Controllers::Ping
  class Get < Pa::Lib::BaseController
    def call(env)
      response = {"pong" => "ok"}
      response.to_json
    end
  end
end
