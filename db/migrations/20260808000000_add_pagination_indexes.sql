-- +micrate Up
CREATE INDEX IF NOT EXISTS idx_clicks_link_id_id ON clicks (link_id, id DESC);
CREATE INDEX IF NOT EXISTS idx_links_user_id_id ON links (user_id, id DESC);

-- +micrate Down
DROP INDEX IF EXISTS idx_clicks_link_id_id;
DROP INDEX IF EXISTS idx_links_user_id_id;
