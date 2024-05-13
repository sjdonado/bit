require "sqlite3"
require "crecto"

module App::Models
  class Link < Crecto::Model
    schema :links do
      field :id, String, primary_key: true
      field :slug, String
      field :url, String
      field :click_counter, Int64, default: 0
    end

    unique_constraint :slug
    validate_required [:slug, :url]
  end
end
