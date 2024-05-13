module App::Middlewares
  class Auth < Kemal::Handler
    include App::Models
    include App::Lib

    exclude ["/api/ping", "/:slug"]

    def call(env)
      return call_next(env) if exclude_match?(env)
      begin
        user = Database.get_by!(User, api_key: env.request.headers["X-Api-Key"])
        env.set "user", user
      rescue exception
        raise App::UnauthorizedException.new(env)
      end
      call_next(env)
    end
  end
end
