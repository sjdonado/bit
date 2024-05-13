require "uuid"
require "option_parser"

require "../app/config/*"
require "../app/lib/*"
require "../app/models/*"

option_parser = OptionParser.parse do |parser|
  parser.on("--create-user=NAME", "Create a new user with the given name") do |name|
    create_user(name)
    exit
  end

  parser.on("--list-users", "List all users") do
    list_users
    exit
  end

  parser.on("--delete-user=USER_ID", "Delete a user by ID") do |user_id|
    delete_user(user_id)
    exit
  end

  if ARGV.empty?
    puts "Usage: ./cli [options]"
    puts "Options:"
    puts "  --create-user=NAME  Create a new user with the given name"
    puts "  --list-users        List all users"
    puts "  --delete-user=USER_ID Delete a user by ID"
  end
end

def create_user(name)
  user = App::Models::User.new
  user.id = UUID.v4.to_s
  user.name = name
  user.api_key = Random::Secure.urlsafe_base64()

  changeset = App::Lib::Database.insert(user)
  if !changeset.valid?
    puts changeset.errors
  else
    puts "New user created: Name: #{user.name}, X-Api-Key: #{user.api_key}"
  end
end

def list_users
  users = App::Lib::Database.all(App::Models::User)

  if users.empty?
    puts "No users found."
  else
    puts "Users:"
    users.each do |user|
      puts "- ID: #{user.id}, Name: #{user.name}, X-Api-Key: #{user.api_key}"
    end
  end
end

def delete_user(user_id)
  result = App::Lib::Database.raw_exec("DELETE FROM users WHERE id = (?)", user_id) # tempfix: Database.delete does not work

  if result.rows_affected == 0
    puts "Failed to delete user: #{result}"
  else
    puts "User with ID #{user_id} deleted successfully."
  end
end
