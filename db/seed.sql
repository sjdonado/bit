INSERT INTO users (name, api_key)
VALUES
('User 1', 'secure_api_key_1'),
('User 2', 'secure_api_key_2');

-- Create 10,000 links (5,000 per user)
WITH RECURSIVE link_numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n+1 FROM link_numbers
    LIMIT 10000
)
INSERT INTO links (user_id, slug, url)
SELECT
    ((n-1) % 2) + 1, -- User ID (1-2)
    'slug' || n,      -- Unique slug
    'https://sjdonado.com/page/' || n
FROM link_numbers;
