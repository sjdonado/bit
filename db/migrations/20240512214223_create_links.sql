-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE links (
	id TEXT PRIMARY KEY NOT NULL,
	user_id TEXT NOT NULL,
	slug VARCHAR(4) UNIQUE NOT NULL,
	url TEXT NOT NULL,
	click_counter INTEGER NOT NULL DEFAULT 0,
	created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,

	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE links;
