require "sqlite3"
require "crecto"

require "./user.cr"

module App::Models
  class Link < Crecto::Model
    schema :links do
      field :id, String, primary_key: true
      field :slug, String
      field :url, String

      belongs_to :user, User
    end

    unique_constraint :slug

    validate_required [:slug, :url]
    validate_format :url, /\A(?:https?:\/\/)?(?:[\w-]+\.)+[\w-]+(?:\/\S*)?/
  end
end
