require "sqlite3"
require"micrate"

require "../app/config/env"

Micrate::DB.connection_url = ENV["DATABASE_URL"]
Micrate::Cli.run_up
