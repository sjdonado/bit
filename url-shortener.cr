require "kemal"

require "./app/config/*"
require "./app/lib/*"
require "./app/models/*"
require "./app/serializers/*"

require "./app/routes"

error 500 { |env| {"error" => "Internal Server Error"}.to_json }
error 401 { |env| {"error" => "Unauthorized"}.to_json }
error 403 { |env| {"error" => "Forbidden"}.to_json }

Kemal.run
