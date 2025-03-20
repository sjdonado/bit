require "sqlite3"
require "crecto"

require "./user.cr"

module App::Models
  class Link < Crecto::Model
    schema :links do
      field :id, Int64, primary_key: true
      field :slug, String
      field :url, String

      belongs_to :user, User
      has_many :clicks, Click
    end

    unique_constraint :slug

    validate_required [:slug, :url]
    validate_format :url, /\A(?:(https?:\/\/)?(?:[\w-]+\.)+[a-z]{2,})(?::\d+)?(?:[\/?#]\S*)?\z/i
  end
end
