require "uuid"
require "option_parser"

require "../app/services/cli"

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

  parser.on("--update-data", "Download all required data files (UA Parser and GeoLite2)") do
    puts "=== Starting data files update ==="
    App::Services::Cli.update_uap_regexes
    App::Services::Cli.download_geolite_db
    puts "=== All data files updated successfully ==="
    exit
  end

  if ARGV.empty?
    puts "Usage: ./cli [options]"
    puts "Options:"
    puts "  --create-user=NAME     Create a new user with the given name"
    puts "  --list-users           List all users"
    puts "  --delete-user=USER_ID  Delete a user by ID"
    puts "  --update-data          Download all required data files"
  end
end
