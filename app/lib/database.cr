require "sqlite3"
require "crecto"
require "./migrator"

module App::Lib
  class Database
    extend Crecto::Repo

    Query = Crecto::Repo::Query

    # crystal-sqlite3 runs these as PRAGMAs on every connection; the migrator and the CLI use the same URL.
    URL = ENV["DATABASE_URL"] + (ENV["DATABASE_URL"].includes?("?") ? "&" : "?") +
          "journal_mode=WAL" +
          "&synchronous=NORMAL" + # Better performance with reasonable safety
          "&foreign_keys=true" +
          # SQLite's busy wait blocks the single-threaded scheduler, so it only covers another process's millisecond writes
          "&busy_timeout=100"

    config do |conf|
      conf.uri = URL
    end

    if ENV["ENV"] == "development"
      Crecto::DbLogger.set_handler(STDOUT)
    end
  end
end
