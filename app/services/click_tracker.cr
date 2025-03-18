require "../lib/*"
require "../models/*"

UserAgent.load_regexes(File.read("data/uap_core_regexes.yaml"))
IpLookup.load_mmdb("data/GeoLite2-Country.mmdb")

module App::Services
  class ClickTracker
    @@queue = Channel(Tuple(String, String, String, String, String)).new(1000)
    @@initialized = false

    def self.init
      return if @@initialized
      @@initialized = true

      # Just use a single worker fiber to process the queue
      spawn do
        Log.info { "ClickTracker worker started" }
        loop do
          begin
            link_id, client_ip, user_agent_str, source, referer = @@queue.receive

            ip_lookup = client_ip != "Unknown" ? IpLookup.new(client_ip) : nil
            country = ip_lookup.try &.country.try &.code

            user_agent = user_agent_str != "Unknown" ? UserAgent.new(user_agent_str) : nil

            click = App::Models::Click.new
            click.id = UUID.v4.to_s
            click.link_id = link_id
            click.country = country
            click.user_agent = user_agent_str
            click.browser = user_agent.try &.family
            click.os = user_agent.try &.os.try &.family
            click.referer = referer

            changeset = App::Lib::Database.insert(click)
            if changeset.errors.any?
              Log.error { "Logging click event failed: #{changeset.errors}" }
            end
          rescue ex
            Log.error { "Error processing click: #{ex.message}" }
            sleep 0.1
          end
        end
      end
    end

    def self.track(link_id : String, client_ip : String, user_agent : String, source : String, referer : String)
      init if !@@initialized

      @@queue.send({link_id, client_ip, user_agent, source, referer})
    end
  end
end
