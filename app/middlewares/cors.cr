module App::Middlewares
  class CORSHandler < Kemal::Handler
    exclude ["/api/ping", "/:slug"]

    def initialize(
      @allow_origin = "*",
      @allow_methods = "GET, POST, PUT, DELETE, OPTIONS",
      @allow_headers = "Content-Type, Accept, Origin, X-Api-Key"
    )
    end

    def call(env)
      return call_next(env) if exclude_match?(env)

      env.response.headers["Access-Control-Allow-Origin"] = @allow_origin
      env.response.headers["Access-Control-Allow-Methods"] = @allow_methods
      env.response.headers["Access-Control-Allow-Headers"] = @allow_headers

      if env.request.method == "OPTIONS"
        env.response.status_code = 200
        env.response.content_type = "text/plain"
        env.response.print("")
        return env
      end

      call_next(env)
    end
  end
end
