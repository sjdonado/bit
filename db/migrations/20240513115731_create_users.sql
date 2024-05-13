-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE users (
	id TEXT PRIMARY KEY NOT NULL,
	name VARCHAR(100) NOT NULL,
	api_key VARCHAR(64) UNIQUE NOT NULL,
	created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE users;
