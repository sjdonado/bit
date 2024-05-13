require "json"

require "../models/link"

module App::Serializers
  class Link
    def initialize(@link : App::Models::Link)
    end

    def to_json(builder : JSON::Builder)
      builder.object do
        builder.field("id", @link.id)
        builder.field("link", "#{ENV["APP_URL"]}/#{@link.slug}")
        builder.field("origin", @link.url)
        builder.field("clicks", @link.click_counter)
      end
    end
  end
end
