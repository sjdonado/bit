require "../config/*"
require "../lib/*"
require "../models/*"

module App::Services::Cli
  def self.create_user(name, api_key = nil)
    user = App::Models::User.new
    user.id = UUID.v4.to_s
    user.name = name
    user.api_key = api_key || Random::Secure.urlsafe_base64()

    changeset = App::Lib::Database.insert(user)
    return changeset.errors if !changeset.valid?

    "New user created: Name: #{user.name}, X-Api-Key: #{user.api_key}"
  end

  def self.list_users
    users = App::Lib::Database.all(App::Models::User)

    return "No users found " if users.empty?

    output = "Users:\n"
    users.each do |user|
      output += "ID: #{user.id}, Name: #{user.name}, X-Api-Key: #{user.api_key}\n"
    end

    output
  end

  def self.delete_user(user_id)
    result = App::Lib::Database.raw_exec("DELETE FROM users WHERE id = (?)", user_id) # tempfix: Database.delete does not work

    return "Failed to delete user: #{result}" if result.rows_affected == 0

    "User with ID #{user_id} deleted successfully"
  end

  def self.setup_admin_user
    admin_name = ENV["ADMIN_NAME"]?
    admin_api_key = ENV["ADMIN_API_KEY"]?

    if admin_name && admin_api_key
      query = App::Lib::Database::Query.where(name: admin_name, api_key: admin_api_key).limit(1)
      existing_user = App::Lib::Database.all(App::Models::User, query).first?

      return if existing_user

      puts "Admin user setup detected. Creating admin user..."
      result = create_user(admin_name, admin_api_key)
      puts result
    else
      puts "Admin setup skipped: Missing ADMIN_NAME or ADMIN_API_KEY environment variables."
    end
  end
end
