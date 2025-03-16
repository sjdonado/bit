require "crecto"

module App::Models
  class Click < Crecto::Model
    schema :clicks do
      field :id, String, primary_key: true
      field :user_agent, String
      field :country, String
      field :browser, String
      field :os, String
      field :referer, String

      belongs_to :link, Link
    end

    validate_required [:user_agent, :referer]
  end
end
