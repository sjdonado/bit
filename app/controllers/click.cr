module App::Controllers
  struct ClickController
    include App::Models
    include App::Lib
    include App::Services

    # Buffered channel to hold click data
    @@click_channel = Channel(NamedTuple(
      link_id: Int64,
      remote_address: String,
      user_agent: String?,
      referer: String
    )).new(10000) # Buffer size

    @@processor_started = begin
      spawn do
        batch_size = 125
        batch = [] of NamedTuple(
          link_id: Int64,
          remote_address: String,
          user_agent: String?,
          referer: String
        )

        loop do
          select
          when click_data = @@click_channel.receive
            batch << click_data

            # Collect clicks until we have a batch or a timeout
            if batch.size >= batch_size
              process_click_batch(batch)
              batch.clear
            end
          when timeout(0.5.seconds)
            # Process whatever we have after timeout
            unless batch.empty?
              process_click_batch(batch)
              batch.clear
            end
          end
        end
      end
      true
    end

    private def self.process_click_batch(batch)
      clicks = [] of App::Models::Click

      batch.each do |click_data|
        begin
          client_ip = IpLookup.ip_from_address(click_data[:remote_address])
          family, _, _, os = UserAgent.parse(click_data[:user_agent] || "")

          click = App::Models::Click.new
          click.link_id = click_data[:link_id]
          click.country = client_ip ? IpLookup.country(client_ip) : nil
          click.user_agent = click_data[:user_agent]
          click.browser = family
          click.os = os.try &.[0]  # OS family
          click.referer = click_data[:referer]

          clicks << click
        rescue ex
          Log.error { "Click data processing error: #{ex.message}" }
        end
      end

      # Batch insert clicks if any were successfully processed
       unless clicks.empty?
        begin
          multi = Crecto::Multi.new
          clicks.each do |click|
            multi.insert(click)
          end
          Database.transaction(multi)
        rescue ex
          Log.error { "Batch click insertion error: #{ex.message}" }
        end
      end
    end

    def self.redirect_handler
      ->(env : HTTP::Server::Context) {
        link_id, url = Database.raw_query("SELECT id, url FROM links WHERE slug = (?) LIMIT 1", env.params.url["slug"]) do |result|
          result.move_next ? {result.read(Int64), result.read(String)} : nil
        end || raise App::NotFoundException.new(env)

        remote_address = env.request.headers["Cf-Connecting-Ip"]? || env.request.remote_address.to_s

        env.response.status_code = 301
        env.response.headers.add("Location", url)
        env.response.headers.add("X-Forwarded-For", remote_address)

        begin
          @@click_channel.send({
            link_id: link_id,
            remote_address: remote_address,
            user_agent: env.request.headers["User-Agent"]?,
            referer: env.request.headers["Referer"]?.try { |r| URI.parse(r).host rescue r } || env.params.query["utm_source"]? || "Direct"
          })
        rescue Channel::ClosedError
          Log.error { "Click channel closed" }
        rescue ex
          Log.error { "Error queuing click: #{ex.message}" }
        end
      }
    end
  end
end
