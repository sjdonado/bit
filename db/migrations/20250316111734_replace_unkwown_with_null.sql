-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
UPDATE clicks SET user_agent = NULL WHERE user_agent = 'Unknown';
UPDATE clicks SET browser = NULL WHERE browser = 'Unknown';
UPDATE clicks SET os = NULL WHERE os = 'Unknown';
UPDATE clicks SET referer = NULL WHERE referer = 'Unknown';

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
UPDATE clicks SET user_agent = 'Unknown' WHERE user_agent IS NULL;
UPDATE clicks SET browser = 'Unknown' WHERE browser IS NULL;
UPDATE clicks SET os = 'Unknown' WHERE os IS NULL;
UPDATE clicks SET referer = 'Unknown' WHERE referer IS NULL;
