-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
DROP INDEX IF EXISTS idx_links_slug;      -- Remove old composite index
CREATE INDEX IF NOT EXISTS idx_links_slug_optimized ON links (slug, url);

-- +micrate Down
-- SQL in section 'Down' is executed when this migration is rolled back
DROP INDEX IF EXISTS idx_links_slug_optimized;
CREATE INDEX IF NOT EXISTS idx_links_slug ON links (id, slug, url);
