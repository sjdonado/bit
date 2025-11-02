module App::Controllers
  struct ClickController
    include App::Models
    include App::Lib
    include App::Services

    def self.redirect_handler
      ->(env : HTTP::Server::Context) {
        link_id, url = Database.raw_query("SELECT id, url FROM links WHERE slug = (?) LIMIT 1", env.params.url["slug"]) do |result|
          result.move_next ? {result.read(Int64), result.read(String)} : nil
        end || raise App::NotFoundException.new(env)

        remote_address = env.request.headers["Cf-Connecting-Ip"]? || env.request.remote_address.to_s

        # Send redirect immediately
        env.response.status_code = 301
        env.response.headers.add("Location", url)
        env.response.headers.add("X-Forwarded-For", remote_address)

        # non-blocking click proccessing
        spawn do
          begin
            client_ip = IpLookup.ip_from_address(remote_address)
            family, _, _, os = UserAgent.parse(env.request.headers["User-Agent"]? || "")

            click = App::Models::Click.new
            click.link_id = link_id
            click.country = client_ip ? IpLookup.country(client_ip) : nil
            click.user_agent = env.request.headers["User-Agent"]?
            click.browser = family
            click.os = os.try &.[0]
            click.referer = env.request.headers["Referer"]?.try { |r| URI.parse(r).host rescue r } || env.params.query["utm_source"]? || "Direct"

            Database.insert(click)
          rescue ex
            Log.error { "Click tracking error: #{ex.message}" }
          end
        end
      }
    end
  end
end
