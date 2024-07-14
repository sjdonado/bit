ENV["ENV"] ||= "development"

{% if env("ENV") != "production" %}
  require "dotenv"
  Dotenv.load ".env.#{ENV["ENV"]}" # File must exist in non-production!
{% end %}

ENV["APP_URL"] ||= "http://localhost:4000"
ENV["DATABASE_URL"] ||= "sqlite3://./sqlite/data.db?journal_mode=wal&synchronous=normal&foreign_keys=true
"
