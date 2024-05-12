require "sqlite3"
require "crecto"

module Pa::Lib
  class Database
    extend Crecto::Repo

    Query = Crecto::Repo::Query
    Multi = Crecto::Repo::Multi

    config do |conf|
      conf.adapter = Crecto::Adapters::SQLite3
      conf.database = ENV["DATABASE_URL"]
    end
  end
end
