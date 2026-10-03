require "option_parser"

require "../app/services/cli"

App::Lib::Migrator.up(App::Lib::Database::URL) unless ARGV.includes?("--migrate-down")

OptionParser.parse do |parser|
  parser.on("--create-user=NAME", "Create a new user with the given name") do |name|
    puts App::Services::Cli.create_user(name)
    exit
  end

  parser.on("--list-users", "List all users") do
    puts App::Services::Cli.list_users
    exit
  end

  parser.on("--delete-user=USER_ID", "Delete a user by ID") do |user_id|
    puts App::Services::Cli.delete_user(user_id)
    exit
  end

  parser.on("--migrate-down", "Roll back the newest applied migration") do
    if name = App::Lib::Migrator.down(App::Lib::Database::URL)
      puts "Rolled back #{name}"
    else
      puts "No applied migration to roll back"
    end
    exit
  rescue ex
    abort "Rollback failed: #{ex.message}"
  end

  parser.on("--update-parsers", "Download UA regexes and/or GeoLite2 database") do
    puts "=== Starting data files update ==="
    App::Services::Cli.update_uap_regexes
    App::Services::Cli.update_geolite_db
    puts "=== Data files updated successfully ==="
    exit
  end

  if ARGV.empty?
    puts "Usage: ./cli [options]"
    puts "Options:"
    puts "  --create-user=NAME     Create a new user with the given name"
    puts "  --list-users           List all users"
    puts "  --delete-user=USER_ID  Delete a user by ID"
    puts "  --migrate-down         Roll back the newest applied migration"
    puts "  --update-parsers          Download all required data files"
  end
end
