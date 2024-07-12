-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE clicks (
	id TEXT PRIMARY KEY NOT NULL,
	link_id TEXT NOT NULL,
	user_agent TEXT,
	language TEXT,
	browser TEXT,
	os TEXT,
	source TEXT,
	created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,

	FOREIGN KEY (link_id) REFERENCES links(id) ON DELETE CASCADE
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE clicks;
