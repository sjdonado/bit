require "../spec_helper"

private def with_migrations(files : Hash(String, String), &)
  dir = File.tempname("migrations")
  Dir.mkdir(dir)
  files.each { |name, sql| File.write(File.join(dir, name), sql) }
  db_file = File.tempname("migrator", ".db")
  yield "sqlite3://#{db_file}", dir
ensure
  FileUtils.rm_rf(dir) if dir
  File.delete?(db_file) if db_file
end

private def table_names(db)
  db.query_all("SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 't_'", as: String).sort
end

describe "App::Lib::Migrator" do
  it "returns only the Up statements" do
    source = <<-SQL
      -- +micrate Up
      CREATE TABLE a (id INTEGER); -- trailing comment
      CREATE INDEX a_id
        ON a (id);
      -- done

      -- +micrate Down
      DROP TABLE a;
      SQL

    App::Lib::Migrator.statements(source).map(&.strip).should eq([
      "CREATE TABLE a (id INTEGER); -- trailing comment",
      "CREATE INDEX a_id\n  ON a (id);",
    ])
  end

  it "rejects unsupported directives and unterminated statements" do
    expect_raises(Exception, /Unsupported migration directive/) do
      App::Lib::Migrator.statements("-- +micrate Up\n-- +micrate StatementBegin\nSELECT 1;\n")
    end
    expect_raises(Exception, /missing trailing ';'/) do
      App::Lib::Migrator.statements("-- +micrate Up\nSELECT 1\n")
    end
  end

  it "applies pending and rolled back versions from micrate history" do
    with_migrations({
      "1_a.sql"   => "-- +micrate Up\nCREATE TABLE t1 (id INTEGER);\n",
      "2_b.sql"   => "-- +micrate Up\nCREATE TABLE t2 (id INTEGER);\n",
      "3_c.sql"   => "-- +micrate Up\nCREATE TABLE t3 (id INTEGER);\n",
      "notes.sql" => "not a migration",
    }) do |url, dir|
      DB.open(url) do |db|
        db.exec "CREATE TABLE micrate_db_version (id INTEGER PRIMARY KEY AUTOINCREMENT, version_id INTEGER NOT NULL, is_applied INTEGER NOT NULL, tstamp TIMESTAMP)"
        db.exec "CREATE TABLE t2 (id INTEGER)"
        [{0, true}, {1, true}, {2, true}, {1, false}].each do |version, applied|
          db.exec "INSERT INTO micrate_db_version (version_id, is_applied) VALUES (?, ?)", version, applied
        end

        App::Lib::Migrator.up(db, dir)
        App::Lib::Migrator.up(db, dir)

        table_names(db).should eq(["t1", "t2", "t3"])
        db.scalar("SELECT COUNT(*) FROM micrate_db_version").should eq(6)
      end
    end
  end

  it "rolls back and raises when a migration fails" do
    with_migrations({
      "1_a.sql" => "-- +micrate Up\nCREATE TABLE t1 (id INTEGER);\nCREATE TABLE t1 (id INTEGER);\n",
    }) do |url, dir|
      expect_raises(Exception, /already exists/) do
        DB.open(url) { |db| App::Lib::Migrator.up(db, dir) }
      end

      DB.open(url) do |db|
        table_names(db).should be_empty
        db.scalar("SELECT COUNT(*) FROM micrate_db_version").should eq(0)
      end
    end
  end
end
