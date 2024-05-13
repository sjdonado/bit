require "kemal"

require "./app/config/*"
require "./app/lib/*"
require "./app/models/*"
require "./app/serializers/*"
require "./app/middlewares/*"

require "./app/routes"

add_context_storage_type(App::Models::User)
add_handler(App::Middlewares::Auth.new)

error 500 { |env| {"error" => "Internal Server Error" }.to_json}
error 401 { |env| {"error" => "Unauthorized" }.to_json}
error 404 { |env| {"error" => "Not Found" }.to_json}

Kemal.run
