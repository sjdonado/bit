require "kemal"

Kemal.config.env = ENV["ENV"]? || "development"
Kemal.config.port = ENV["PORT"]?.try(&.to_i) || 4000
Kemal.config.host_binding = ENV["HOST"]? || "0.0.0.0"

Kemal.config.logging = true
