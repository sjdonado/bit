require "../config/*"
require "../lib/*"
require "../models/*"

module App::Services::Cli
  def self.create_user(name)
    user = App::Models::User.new
    user.id = UUID.v4.to_s
    user.name = name
    user.api_key = Random::Secure.urlsafe_base64()

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
end
