require "json"

require "../models/link"
require "./click"

module App::Serializers
  class Link
    getter refer

    def initialize(@link : App::Models::Link)
      @refer = "#{ENV["APP_URL"]}/#{@link.slug}"
    end

    def to_json(builder : JSON::Builder)
      builder.object do
        builder.field("id", @link.id)
        builder.field("refer", @refer)
        builder.field("origin", @link.url)
        builder.field("clicks", @link.clicks.map { |click| App::Serializers::Click.new(click) })
      end
    end
  end
end
