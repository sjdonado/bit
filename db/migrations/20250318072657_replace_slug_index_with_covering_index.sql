-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
DROP INDEX IF EXISTS index_links_slug;
-- Create the new covering index that includes id and url
CREATE INDEX IF NOT EXISTS idx_links_slug ON links (id, slug, url);

-- +micrate Down
-- SQL in section 'Down' is executed when this migration is rolled back
DROP INDEX IF EXISTS idx_links_slug;
CREATE INDEX IF NOT EXISTS index_links_slug ON links (slug);
