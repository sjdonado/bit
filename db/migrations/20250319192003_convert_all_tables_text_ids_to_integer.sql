-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
-- 1. Create new users table with INTEGER PK
CREATE TABLE users_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    api_key VARCHAR(64) UNIQUE NOT NULL,
    created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Create a mapping table to track old and new user IDs
CREATE TEMPORARY TABLE user_id_map (
    old_id TEXT,
    new_id INTEGER
);

-- Insert users data and capture the mappings
INSERT INTO users_new (name, api_key, created_at, updated_at)
SELECT name, api_key, created_at, updated_at FROM users;

INSERT INTO user_id_map
SELECT u.id, u_new.id
FROM users u
JOIN users_new u_new ON u_new.api_key = u.api_key;

-- 2. Create new links table with INTEGER PK
CREATE TABLE links_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    slug VARCHAR(8) UNIQUE NOT NULL,
    url TEXT NOT NULL,
    created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users_new(id) ON DELETE CASCADE
);

-- Create a mapping table for links
CREATE TEMPORARY TABLE link_id_map (
    old_id TEXT,
    new_id INTEGER
);

-- Insert links data with new user_id foreign keys
INSERT INTO links_new (user_id, slug, url, created_at, updated_at)
SELECT 
    (SELECT new_id FROM user_id_map WHERE old_id = l.user_id),
    l.slug,
    l.url,
    l.created_at,
    l.updated_at
FROM links l;

-- Create the mapping for links
INSERT INTO link_id_map
SELECT l.id, l_new.id
FROM links l
JOIN links_new l_new ON l_new.slug = l.slug AND l_new.url = l.url;

-- 3. Create new clicks table with INTEGER PK
CREATE TABLE clicks_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    link_id INTEGER NOT NULL,
    user_agent TEXT,
    browser TEXT,
    os TEXT,
    referer TEXT,
    country TEXT,
    created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (link_id) REFERENCES links_new(id) ON DELETE CASCADE
);

-- Insert clicks data with new link_id foreign keys
INSERT INTO clicks_new (link_id, user_agent, browser, os, referer, country, created_at, updated_at)
SELECT 
    (SELECT new_id FROM link_id_map WHERE old_id = c.link_id),
    c.user_agent,
    c.browser,
    c.os,
    c.referer,
    c.country,
    c.created_at,
    c.updated_at
FROM clicks c;

-- 4. Drop old tables and rename new tables
DROP TABLE clicks;
DROP TABLE links;
DROP TABLE users;

ALTER TABLE clicks_new RENAME TO clicks;
ALTER TABLE links_new RENAME TO links;
ALTER TABLE users_new RENAME TO users;

-- 5. Drop unused indexes
DROP INDEX IF EXISTS index_users_api_key;
DROP INDEX IF EXISTS idx_links_slug;
DROP INDEX IF EXISTS idx_links_slug_optimized;

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
