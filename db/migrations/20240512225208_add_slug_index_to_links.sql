-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE INDEX IF NOT EXISTS index_links_slug ON links (slug);

-- +micrate Down
-- SQL in section 'Down' is executed when this migration is rolled back
DROP INDEX IF EXISTS index_links_slug;
