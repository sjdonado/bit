-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE links (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	slug VARCHAR(100) UNIQUE NOT NULL,
	url TEXT NOT NULL,
	click_counter INTEGER DEFAULT 0,
	created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE links;
