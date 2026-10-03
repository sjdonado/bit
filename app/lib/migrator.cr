require "db"
require "log"

module App::Lib
  # Applies `db/migrations/*.sql` files in version order, one transaction each: `up` runs the `-- +micrate Up` section of every pending file, `down` runs the `-- +micrate Down` section of the newest applied one. Statements end at a line ending with `;` (as in micrate, `--` always starts a comment, even inside a string literal). State lives in micrate's `micrate_db_version` table, so databases migrated by micrate keep their history.
  module Migrator
    Log = ::Log.for(self)
    DIR = "db/migrations"

    def self.up(url : String)
      DB.open(url) { |db| up(db) }
    end

    # Returns the rolled back file name, or nil when nothing is applied.
    def self.down(url : String) : String?
      DB.open(url) { |db| down(db) }
    end

    def self.up(db : DB::Database, dir = DIR)
      applied = applied_versions(db)
      migrations(dir).each do |version, path|
        apply(db, path, version, "Up") unless applied.includes?(version)
      end
    end

    def self.down(db : DB::Database, dir = DIR) : String?
      applied = applied_versions(db)
      return if applied.empty?
      version = applied.max
      path = migrations(dir).to_h[version]? || raise "No migration file for applied version #{version}"
      raise "#{File.basename(path)} is irreversible: its Down section is empty" if statements(File.read(path), "Down").empty?
      apply(db, path, version, "Down")
    end

    def self.statements(source : String, section = "Up") : Array(String)
      statements = [] of String
      buffer = String::Builder.new
      active = false

      source.each_line do |line|
        case directive = line.strip
        when "-- +micrate Up", "-- +micrate Down"
          active = directive == "-- +micrate #{section}"
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

    # Versions whose latest row says applied; a later row with is_applied = 0 means rolled back.
    private def self.applied_versions(db) : Set(Int64)
      db.exec <<-SQL
        CREATE TABLE IF NOT EXISTS micrate_db_version (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          version_id INTEGER NOT NULL,
          is_applied INTEGER NOT NULL,
          tstamp TIMESTAMP
        )
        SQL

      latest = {} of Int64 => Bool
      db.query_each("SELECT version_id, is_applied FROM micrate_db_version ORDER BY id") do |rs|
        latest[rs.read(Int64)] = rs.read(Bool)
      end
      # Version 0 is the row micrate writes when it creates the table.
      latest.select { |version, applied| applied && version > 0 }.keys.to_set
    end

    private def self.migrations(dir) : Array({Int64, String})
      Dir.glob("#{dir}/*.sql").sort.compact_map do |path|
        File.basename(path)[/^(\d+)_/, 1]?.try { |version| {version.to_i64, path} }
      end
    end

    private def self.apply(db, path, version, section)
      name = File.basename(path)
      db.using_connection do |cnn|
        # PRAGMA foreign_keys is a no-op inside a transaction, so it is turned off before one starts; otherwise DROP TABLE on a parent table cascades into its child rows.
        foreign_keys = cnn.scalar("PRAGMA foreign_keys").as(Int64)
        # The macOS system SQLite defaults to ON, which leaves REFERENCES pointing at a table's pre-rename name.
        legacy_alter_table = cnn.scalar("PRAGMA legacy_alter_table").as(Int64)
        cnn.exec "PRAGMA foreign_keys=OFF"
        cnn.exec "PRAGMA legacy_alter_table=OFF"
        begin
          # IMMEDIATE takes the write lock up front, so a concurrent writer makes it wait for busy_timeout instead of failing mid-migration.
          cnn.exec "BEGIN IMMEDIATE"
          begin
            # Rows orphaned while foreign keys were not enforced are tolerated; a migration may not add more.
            before = foreign_key_violations(cnn)
            statements(File.read(path), section).each { |sql| cnn.exec(sql) }
            added = foreign_key_violations(cnn) - before
            raise "#{name}: #{added.size} new foreign key violations, first in #{added.first[0]}" unless added.empty?
            cnn.exec(
              "INSERT INTO micrate_db_version (version_id, is_applied, tstamp) VALUES (?, ?, ?)",
              version, section == "Up", Time.local
            )
            cnn.exec "COMMIT"
          rescue ex
            cnn.exec "ROLLBACK" rescue nil
            raise ex
          end
        ensure
          cnn.exec "PRAGMA foreign_keys=#{foreign_keys}"
          cnn.exec "PRAGMA legacy_alter_table=#{legacy_alter_table}"
        end
      end
      Log.info { "#{section == "Up" ? "Applied" : "Rolled back"} #{name}" }
      name
    end

    private def self.foreign_key_violations(cnn) : Set({String, Int64?, String})
      violations = Set({String, Int64?, String}).new
      cnn.query_each("PRAGMA foreign_key_check") do |rs|
        violations << {rs.read(String), rs.read(Int64?), rs.read(String)}
      end
      violations
    end
  end
end
