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

        begin
          clicks = @link.clicks
          unless clicks.empty?
            builder.field("clicks", clicks.map { |click| App::Serializers::Click.new(click) })
          end
        rescue Crecto::AssociationNotLoaded
          # Association not loaded, skip this field silently
        end
      end
    end
  end
end
