require "json"

require "../models/click"

module App::Serializers
  class Click
    def initialize(@click : App::Models::Click)
    end

    def to_json(builder : JSON::Builder)
      builder.object do
        builder.field("id", @click.id)
        builder.field("user_agent", @click.user_agent)
        builder.field("country", @click.country)
        builder.field("browser", @click.browser)
        builder.field("os", @click.os)
        builder.field("referer", @click.referer)
        builder.field("created_at", @click.created_at)
      end
    end
  end
end
