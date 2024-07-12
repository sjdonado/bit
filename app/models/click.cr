require "crecto"

module App::Models
  class Click < Crecto::Model
    schema :clicks do
      field :id, String, primary_key: true
      field :user_agent, String
      field :language, String
      field :browser, String
      field :os, String
      field :source, String

      belongs_to :link, Link
    end

    validate_required [:user_agent, :language, :source]
  end
end
