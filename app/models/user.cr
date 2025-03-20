require "sqlite3"
require "crecto"

module App::Models
  class User < Crecto::Model
    schema :users do
      field :id, Int64, primary_key: true
      field :name, String
      field :api_key, String
    end

    validate_required [:name, :api_key]

    has_many :links, Link, dependent: :destroy
  end
end
