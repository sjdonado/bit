require "sqlite3"
require "crecto"
require "./migrator"

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
        "&foreign_keys=true"

      conf.uri = db_url
    end

    if ENV["ENV"] == "development"
      Crecto::DbLogger.set_handler(STDOUT)
    end

    Migrator.up(ENV["DATABASE_URL"])
  end
end
