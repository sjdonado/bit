require "sqlite3"
require "crecto"

module App::Lib
  class Database
    extend Crecto::Repo

    config do |conf|
      conf.uri = ENV["DATABASE_URL"]
    end

    Crecto::DbLogger.set_handler(STDOUT)
  end
end
