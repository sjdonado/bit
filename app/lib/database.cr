require "sqlite3"
require "crecto"

module App::Lib
  class Database
    extend Crecto::Repo

    Query = Crecto::Repo::Query

    config do |conf|
      conf.uri = ENV["DATABASE_URL"]
    end

    if ENV["ENV"] == "development"
      Crecto::DbLogger.set_handler(STDOUT)
    end
  end
end
