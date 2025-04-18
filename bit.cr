require "kemal"

require "./app/config/*"
require "./app/lib/*"
require "./app/models/*"
require "./app/serializers/*"
require "./app/middlewares/*"
require "./app/services/*"

require "./app/routes"

add_context_storage_type(App::Models::User)
App::Services::Cli.setup_admin_user

Kemal.run
