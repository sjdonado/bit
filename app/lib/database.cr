require "sqlite3"
require "crecto"
require"micrate"

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

    def self.run_migrations
      Micrate::DB.connection_url = ENV["DATABASE_URL"]
      Micrate::Cli.run_up
    end

    run_migrations
  end
end
