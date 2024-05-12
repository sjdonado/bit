ENV["APP_ENV"] ||= "development"

{% if env("APP_ENV") != "production" %}
  require "dotenv"
  Dotenv.load ".env.#{ENV["APP_ENV"]}" # File must exist in non-production!
{% end %}
