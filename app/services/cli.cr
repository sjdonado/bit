require "file_utils"
require "http/client"

require "../config/*"
require "../lib/*"
require "../models/*"

module App::Services::Cli
  def self.create_user(name, api_key = nil)
    user = App::Models::User.new
    user.name = name
    user.api_key = api_key || Random::Secure.urlsafe_base64()

    changeset = App::Lib::Database.insert(user)
    return changeset.errors unless changeset.valid?

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

  def self.update_uap_regexes
    puts "Downloading User-Agent Parser core regexes..."

    FileUtils.mkdir_p("data")
    url = "https://raw.githubusercontent.com/ua-parser/uap-core/master/regexes.yaml"
    output_file = "data/uap_core_regexes.yaml"

    begin
      http_get_with_redirect(url) do |response|
        File.write(output_file, response.body_io.gets_to_end)
      end
      puts "User-Agent regexes downloaded to #{output_file}"
    rescue e
      puts "Error: Failed to download UAP core regexes: #{e.message}"
    end
  end

  def self.update_geolite_db
    puts "Downloading GeoLite2 Country database..."

    FileUtils.mkdir_p("data")
    url = "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb"
    output_file = "data/GeoLite2-Country.mmdb"

    begin
      File.open(output_file, "wb") do |file|
        http_get_with_redirect(url) do |response|
          IO.copy(response.body_io, file)
        end
      end
      puts "GeoLite2 database downloaded to #{output_file}"
    rescue e
      puts "Error: Failed to download GeoLite2 database: #{e.message}"
    end
  end

  private def self.http_get_with_redirect(url : String, max_redirects = 5)
    redirects = 0

    while redirects < max_redirects
      uri = URI.parse(url)
      client = HTTP::Client.new(uri)

      success = false
      follow_redirect = false
      redirect_url = nil

      begin
        client.get(uri.request_target) do |response|
          case response.status_code
          when 200
            yield response
            success = true
          when 301, 302
            if new_location = response.headers["Location"]?
              puts "Following redirect to: #{new_location}"
              redirect_url = new_location
              follow_redirect = true
            else
              raise "Received redirect status but no Location header"
            end
          else
            raise "Failed request with status code: #{response.status_code}"
          end
        end
      ensure
        client.close
      end

      return if success

      if follow_redirect && redirect_url
        url = redirect_url
        redirects += 1
      else
        break
      end
    end

    raise "Too many redirects (#{max_redirects})"
  end
end
