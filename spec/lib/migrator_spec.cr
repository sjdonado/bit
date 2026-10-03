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
    App::Lib::Migrator.statements(source, "Down").map(&.strip).should eq(["DROP TABLE a;"])
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

  it "upgrades a July 2024 database with foreign keys on without cascading deletes" do
    files = Dir.glob("db/migrations/*.sql").sort
    with_migrations(files.first(5).to_h { |path| {File.basename(path), File.read(path)} }) do |url, dir|
      DB.open("#{url}?foreign_keys=true") do |db|
        App::Lib::Migrator.up(db, dir)
        db.exec "INSERT INTO users (id, name, api_key) VALUES ('u1', 'User', 'key')"
        db.exec "INSERT INTO links (id, user_id, slug, url) VALUES ('l1', 'u1', 'abcd', 'https://example.com')"
        3.times { |i| db.exec "INSERT INTO clicks (id, link_id) VALUES (?, 'l1')", "c#{i}" }

        files.skip(5).each { |path| FileUtils.cp(path, dir) }
        App::Lib::Migrator.up(db, dir)

        db.scalar("SELECT COUNT(*) FROM clicks").should eq(3)
        db.scalar("PRAGMA foreign_keys").should eq(1)
        # Foreign keys must point at the renamed tables, not at links_new or users_new.
        db.exec "INSERT INTO clicks (link_id) SELECT id FROM links"
        db.scalar("SELECT COUNT(*) FROM clicks").should eq(4)
      end
    end
  end

  it "tolerates existing orphan rows but rejects new foreign key violations" do
    with_migrations({
      "1_a.sql" => "-- +micrate Up\nCREATE TABLE p (id INTEGER PRIMARY KEY);\nCREATE TABLE c (p_id INTEGER REFERENCES p (id));\n",
    }) do |url, dir|
      DB.open("#{url}?foreign_keys=true&max_pool_size=1") do |db|
        App::Lib::Migrator.up(db, dir)
        db.exec "PRAGMA foreign_keys=OFF"
        db.exec "INSERT INTO c (p_id) VALUES (1)"
        db.exec "PRAGMA foreign_keys=ON"

        File.write(File.join(dir, "2_b.sql"), "-- +micrate Up\nCREATE TABLE t2 (id INTEGER);\n")
        App::Lib::Migrator.up(db, dir)
        table_names(db).should eq(["t2"])

        File.write(File.join(dir, "3_c.sql"), "-- +micrate Up\nINSERT INTO c (p_id) VALUES (2);\n")
        expect_raises(Exception, /3_c.sql: 1 new foreign key violations/) { App::Lib::Migrator.up(db, dir) }
        db.scalar("SELECT COUNT(*) FROM c").should eq(1)
        db.scalar("SELECT COUNT(*) FROM micrate_db_version WHERE version_id = 3").should eq(0)
        db.scalar("PRAGMA foreign_keys").should eq(1)
      end
    end
  end

  it "rolls back the newest applied migration" do
    with_migrations({
      "1_a.sql" => "-- +micrate Up\nCREATE TABLE t1 (id INTEGER);\n-- +micrate Down\nDROP TABLE t1;\n",
      "2_b.sql" => "-- +micrate Up\nCREATE TABLE t2 (id INTEGER);\n-- +micrate Down\nDROP TABLE t2;\n",
    }) do |url, dir|
      DB.open(url) do |db|
        App::Lib::Migrator.up(db, dir)
        App::Lib::Migrator.down(db, dir).should eq("2_b.sql")
        table_names(db).should eq(["t1"])

        App::Lib::Migrator.up(db, dir)
        table_names(db).should eq(["t1", "t2"])

        App::Lib::Migrator.down(db, dir)
        App::Lib::Migrator.down(db, dir).should eq("1_a.sql")
        table_names(db).should be_empty
        App::Lib::Migrator.down(db, dir).should be_nil
      end
    end
  end

  it "rolls back the newest real migration and refuses an irreversible one" do
    files = Dir.glob("db/migrations/*.sql").sort
    indexes = ->(db : DB::Database) { db.query_all("SELECT name FROM sqlite_master WHERE type = 'index' AND name IN ('idx_clicks_link_id_id', 'idx_links_user_id_id')", as: String) }
    with_migrations(files.to_h { |path| {File.basename(path), File.read(path)} }) do |url, dir|
      DB.open("#{url}?foreign_keys=true") do |db|
        App::Lib::Migrator.up(db, dir)
        indexes.call(db).size.should eq(2)

        App::Lib::Migrator.down(db, dir).should eq(File.basename(files.last))
        indexes.call(db).should be_empty

        App::Lib::Migrator.up(db, dir)
        indexes.call(db).size.should eq(2)

        App::Lib::Migrator.down(db, dir)
        expect_raises(Exception, /20250319192003_convert_all_tables_text_ids_to_integer.sql is irreversible/) do
          App::Lib::Migrator.down(db, dir)
        end
      end
    end
  end

  it "never rolls back micrate's version 0 row" do
    with_migrations({} of String => String) do |url, dir|
      DB.open(url) do |db|
        App::Lib::Migrator.up(db, dir)
        db.exec "INSERT INTO micrate_db_version (version_id, is_applied) VALUES (0, 1)"
        App::Lib::Migrator.down(db, dir).should be_nil
      end
    end
  end

  it "refuses to roll back an applied version without a file" do
    with_migrations({"1_a.sql" => "-- +micrate Up\nCREATE TABLE t1 (id INTEGER);\n-- +micrate Down\nDROP TABLE t1;\n"}) do |url, dir|
      DB.open(url) do |db|
        App::Lib::Migrator.up(db, dir)
        db.exec "INSERT INTO micrate_db_version (version_id, is_applied) VALUES (2, 1)"
        expect_raises(Exception, /No migration file for applied version 2/) { App::Lib::Migrator.down(db, dir) }
        table_names(db).should eq(["t1"])
      end
    end
  end
end
