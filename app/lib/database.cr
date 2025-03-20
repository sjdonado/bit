require "sqlite3"
require "crecto"
require "micrate"

module App::Lib
  class Database
    extend Crecto::Repo

    Query = Crecto::Repo::Query

    config do |conf|
      base_url = ENV["DATABASE_URL"]
      separator = base_url.includes?("?") ? "&" : "?"

      db_url = base_url + separator +
        "&journal_mode=WAL" +
        "&synchronous=NORMAL" +      # Better performance with reasonable safety
        "&foreign_keys=true" +
        "&cache_size=10000" +        # Larger cache (10MB) for frequently accessed data
        "&wal_autocheckpoint=10000"  # Less frequent checkpoints

      conf.uri = db_url
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
