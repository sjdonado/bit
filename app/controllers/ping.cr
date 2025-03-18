require "../lib/controller.cr"

module App::Controllers
  class PingController < App::Lib::BaseController
    def initialize(@env : HTTP::Server::Context)
      super(@env)
    end

    def ping
      render_json({data: "pong"})
    end
  end
end
