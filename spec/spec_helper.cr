require "uuid"
require "file_utils"

require "spec-kemal"
require "micrate"

require "dotenv"
Dotenv.load ".env.#{ENV["ENV"]}"

require "../bit"

Spec.before_suite do
  # Delete the SQLite database file if it exists
  db_file_path = ENV["DATABASE_URL"].split("sqlite3://").last.split("?").first
  if File.exists?(db_file_path)
    File.delete(db_file_path)
  end

  Micrate::DB.connection_url = ENV["DATABASE_URL"]
  Micrate::Cli.run_up

  Kemal.config.logging = false
end

def create_test_user
  user = App::Models::User.new
  user.id = UUID.v4.to_s
  user.name = "Tester"
  user.api_key = Random::Secure.urlsafe_base64()

  changeset = App::Lib::Database.insert(user)
  if !changeset.valid?
    error_messages = changeset.errors.map { |error| "#{error}" }.join(", ")
    raise "Test user creation failed #{error_messages}"
  end

  user
end

def create_test_link(user, url)
  link = App::Models::Link.new
  link.id = UUID.v4.to_s
  link.slug = App::Services::SlugService.shorten_url(url)
  link.url = url
  link.user = user

  changeset = App::Lib::Database.insert(link)
  unless changeset.valid?
    error_messages = changeset.errors.map { |error| "#{error}" }.join(", ")
    raise "Test link creation failed: #{error_messages} #{url} #{link.slug}"
  end

  link.clicks = [] of App::Models::Click

  link
end

def get_test_link(link_id)
  query = App::Lib::Database::Query.where(id: link_id.as(String)).limit(1)
  link = App::Lib::Database.all(App::Models::Link, query, preload: [:clicks]).first?

  raise "Link not found" if link.nil?

  link
end

def delete_test_link(link_id)
  App::Lib::Database.raw_exec("DELETE FROM links WHERE id = (?)", link_id) # tempfix: Database.delete does not work
end
