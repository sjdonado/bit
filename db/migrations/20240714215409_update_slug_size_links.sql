-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied

-- Step 1: Create a new table with the desired column type
CREATE TABLE links_new (
  id TEXT PRIMARY KEY NOT NULL,
  user_id TEXT NOT NULL,
  slug VARCHAR(8) UNIQUE NOT NULL,
  url TEXT NOT NULL,
  created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Step 2: Copy data from the old table to the new table
INSERT INTO links_new (id, user_id, slug, url, created_at, updated_at)
SELECT id, user_id, slug, url, created_at, updated_at FROM links;

-- Step 3: Drop the old table
DROP TABLE links;

-- Step 4: Rename the new table to the old table's name
ALTER TABLE links_new RENAME TO links;

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back

-- Step 1: Create a new table with the original column type
CREATE TABLE links_old (
  id TEXT PRIMARY KEY NOT NULL,
  user_id TEXT NOT NULL,
  slug VARCHAR(4) UNIQUE NOT NULL,
  url TEXT NOT NULL,
  created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Step 2: Copy data from the current table to the old table
INSERT INTO links_old (id, user_id, slug, url, created_at, updated_at)
SELECT id, user_id, substr(slug, 1, 4), url, created_at, updated_at FROM links;

-- Step 3: Drop the current table
DROP TABLE links;

-- Step 4: Rename the old table to the current table's name
ALTER TABLE links_old RENAME TO links;
