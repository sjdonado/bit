require "kemal"

require "./config/*"
require "./services/*"
require "./routes"

error 500 { |env| {"status" => 500, "error" => "Internal Server Error"}.to_json }
error 401 { |env| {"status" => 401, "error" => "Unauthorized"}.to_json }
error 403 { |env| {"status" => 403, "error" => "Forbidden"}.to_json }
error 404 { |env| {"status" => 404, "error" => "Not Found"}.to_json }

Kemal.run
