require "sqlite3"
require "crecto"

module App::Lib
  class Database
    extend Crecto::Repo

    Query = Crecto::Repo::Query
    Multi = Crecto::Repo::Multi

    config do |conf|
      conf.uri = ENV["DATABASE_URL"]
    end
  end
end
