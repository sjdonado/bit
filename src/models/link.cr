require "sqlite3"
require "crecto"

module App::Models
  class Link < Crecto::Model
    schema :links do
      field :slug, String
      field :url, String
      field :click_counter, Int64
    end

    validate_required [:slug, :url]
  end
end
