require "user_agent_parser"

UserAgent.load_regexes(File.read("data/uap_core_regexes.yaml"))

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

        env.response.status_code = 301
        env.response.headers.add("Location", url)
        env.response.headers.add("X-Forwarded-For", remote_address)

        spawn do
          begin
            client_ip = IpLookup.ip_from_address(remote_address)
            user_agent_str = env.request.headers["User-Agent"]?
            referer = env.request.headers["Referer"]?.try { |r| URI.parse(r).host rescue r } || env.params.query["utm_source"]? || "Direct"

            ua_parser = user_agent_str ? UserAgent.new(user_agent_str) : nil

            click = App::Models::Click.new
            click.link_id = link_id
            click.country = client_ip ? IpLookup.country(client_ip) : nil
            click.user_agent = user_agent_str
            click.browser = ua_parser.try(&.family)
            click.os = ua_parser.try(&.os.try(&.family))
            click.referer = referer

            Database.insert(click)
          rescue ex
            Log.error { "Click tracking error: #{ex.message}" }
          end
        end
      }
    end
  end
end
