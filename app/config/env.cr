ENV["ENV"] ||= "development"

{% if env("ENV") != "production" %}
  require "dotenv"
  Dotenv.load ".env.#{ENV["ENV"]}" # File must exist in non-production!
{% end %}
