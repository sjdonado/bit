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
        builder.field("language", @click.language)
        builder.field("browser", @click.browser)
        builder.field("os", @click.os)
        builder.field("source", @click.source)
        builder.field("created_at", @click.created_at)
      end
    end
  end
end
