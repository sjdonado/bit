require "../spec_helper"
require "../../app/services/cli"

describe "App::Services::Cli" do
  it "creates a new user" do
    name = "testuser"
    output = App::Services::Cli.create_user(name)

    output.should contain "New user created: Name: testuser"
  end

  it "lists all users" do
    App::Services::Cli.create_user("user1")
    App::Services::Cli.create_user("user2")

    output = App::Services::Cli.list_users

    output.should contain "Users:"
    output.should contain "Name: user1"
    output.should contain "Name: user2"
  end

  it "deletes a user by ID" do
    App::Services::Cli.create_user("user_to_delete")
    user = App::Lib::Database.all(App::Models::User).first

    output = App::Services::Cli.delete_user(user.id)

    output.should contain "User with ID #{user.id} deleted successfully"
  end

  it "handles deletion of non-existent user" do
    output = App::Services::Cli.delete_user("non-existent-id")

    output.should contain "Failed to delete user"
  end

  it "sets up an admin user if environment variables are present" do
    ENV["ADMIN_NAME"] = "adminuser"
    ENV["ADMIN_API_KEY"] = "secure_admin_key"

    App::Services::Cli.setup_admin_user

    admin_user = App::Lib::Database.all(App::Models::User).find { |u| u.name == "adminuser" }
    admin_user.should_not be_nil
    admin_user = admin_user.not_nil!

    admin_user.api_key.should eq "secure_admin_key"

    App::Services::Cli.delete_user(admin_user.id)
  end

  it "skips admin setup if environment variables are missing" do
    ENV.delete("ADMIN_NAME")
    ENV.delete("ADMIN_API_KEY")

    App::Services::Cli.setup_admin_user

    users = App::Lib::Database.all(App::Models::User)
    users.none? { |u| u.name == "adminuser" }.should be_true
  end
end
