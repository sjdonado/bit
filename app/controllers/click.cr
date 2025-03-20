require "user_agent_parser"

UserAgent.load_regexes(File.read("data/uap_core_regexes.yaml"))
IpLookup.load_mmdb("data/GeoLite2-Country.mmdb")

module App::Controllers
  struct ClickController
    include App::Models
    include App::Lib
    include App::Services

    def self.redirect_handler
      ->(env : HTTP::Server::Context) {
        slug = env.params.url["slug"]

        link_data = nil
        Database.raw_query("SELECT id, url FROM links WHERE slug = (?) LIMIT 1", slug) do |result|
          if result.move_next
            link_data = {result.read(Int64), result.read(String)}
          end
        end
        raise App::NotFoundException.new(env) unless link_data

        link_id, url = link_data
        client_ip = IpLookup.ip_from_address(env.request.headers["Cf-Connecting-Ip"]? || env.request.remote_address.to_s)

        spawn do
          begin
            user_agent_str = env.request.headers["User-Agent"]?
            referer = env.request.headers["Referer"]?.try { |r| URI.parse(r).host rescue r } || env.params.query["utm_source"]? || "Direct"

            ua_parser = user_agent_str ? UserAgent.new(user_agent_str) : nil

            click = App::Models::Click.new
            click.link_id = link_id
            click.country = client_ip ? IpLookup.new(client_ip).try(&.country.try(&.code)) : nil
            click.user_agent = ua_parser.to_s
            click.browser = ua_parser.try(&.family)
            click.os = ua_parser.try(&.os.try(&.family))
            click.referer = referer

            Database.insert(click)
          rescue ex
            Log.error { "Click tracking error: #{ex.message}" }
          end
        end

        env.response.status_code = 301
        env.response.headers.add("Location", url)
        env.response.headers.add("X-Forwarded-For", client_ip.to_s)
        env.response.print ""
        env.response.close

        return
      }
    end
  end
end
