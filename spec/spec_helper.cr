require "uuid"

require "spec-kemal"
require "micrate"

require "../url-shortener"

Spec.before_suite do
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
    raise "Test user creation failed"
  end

  user
end

def create_test_link(user, url)
  link = App::Models::Link.new
  link.id = UUID.v4.to_s
  link.url = url
  link.slug = Random::Secure.urlsafe_base64(4)
  link.user = user

  changeset = App::Lib::Database.insert(link)
  if !changeset.valid?
    raise "Test link creation failed"
  end

  link
end

def get_test_link(link_id)
  App::Lib::Database.get!(App::Models::Link, link_id)
end

def delete_test_link(link_id)
  App::Lib::Database.raw_exec("DELETE FROM links WHERE id = (?)", link_id) # tempfix: Database.delete does not work
end
