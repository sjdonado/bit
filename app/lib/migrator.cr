require "db"
require "log"

module App::Lib
  # Applies pending `db/migrations/*.sql` files in version order, one transaction each. Only the `-- +micrate Up` section runs; statements end at a line ending with `;` (as in micrate, `--` always starts a comment, even inside a string literal). State lives in micrate's `micrate_db_version` table, so databases migrated by micrate keep their history.
  module Migrator
    Log = ::Log.for(self)
    DIR = "db/migrations"

    def self.up(url : String)
      DB.open(url) { |db| up(db) }
    end

    def self.up(db : DB::Database, dir = DIR)
      db.exec <<-SQL
        CREATE TABLE IF NOT EXISTS micrate_db_version (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          version_id INTEGER NOT NULL,
          is_applied INTEGER NOT NULL,
          tstamp TIMESTAMP
        )
        SQL

      # The latest row per version says whether it is applied or rolled back.
      applied = {} of Int64 => Bool
      db.query_each("SELECT version_id, is_applied FROM micrate_db_version ORDER BY id") do |rs|
        applied[rs.read(Int64)] = rs.read(Bool)
      end

      Dir.glob("#{dir}/*.sql").sort.each do |path|
        name = File.basename(path)
        next unless version = name[/^(\d+)_/, 1]?.try(&.to_i64)
        next if applied[version]?

        db.transaction do |tx|
          statements(File.read(path)).each { |sql| tx.connection.exec(sql) }
          tx.connection.exec(
            "INSERT INTO micrate_db_version (version_id, is_applied, tstamp) VALUES (?, ?, ?)",
            version, true, Time.local
          )
        end
        Log.info { "Applied #{name}" }
      end
    end

    def self.statements(source : String) : Array(String)
      statements = [] of String
      buffer = String::Builder.new
      active = false

      source.each_line do |line|
        case directive = line.strip
        when "-- +micrate Up"   then active = true
        when "-- +micrate Down" then active = false
        when .starts_with?("-- +micrate")
          raise "Unsupported migration directive: #{directive}"
        else
          next unless active
          buffer << line << '\n'
          if line.split("--", 2).first.rstrip.ends_with?(';')
            statements << buffer.to_s
            buffer = String::Builder.new
          end
        end
      end

      leftover = buffer.to_s.lines.map(&.split("--", 2).first.strip).reject(&.empty?)
      raise "Migration statement missing trailing ';'" unless leftover.empty?
      statements
    end
  end
end
