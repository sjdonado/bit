-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE clicks ADD COLUMN country TEXT;
ALTER TABLE clicks RENAME COLUMN source TO referer;

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
ALTER TABLE clicks RENAME COLUMN referer TO source;
