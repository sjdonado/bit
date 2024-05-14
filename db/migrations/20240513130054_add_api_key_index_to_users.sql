-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE INDEX IF NOT EXISTS index_users_api_key ON users (api_key);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP INDEX IF EXISTS index_users_api_key;
