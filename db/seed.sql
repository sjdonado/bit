-- Create 10 users
INSERT INTO users (name, api_key)
VALUES
('User 1', 'secure_api_key_1'),
('User 2', 'secure_api_key_2'),
('User 3', 'secure_api_key_3'),
('User 4', 'secure_api_key_4'),
('User 5', 'secure_api_key_5'),
('User 6', 'secure_api_key_6'),
('User 7', 'secure_api_key_7'),
('User 8', 'secure_api_key_8'),
('User 9', 'secure_api_key_9'),
('User 10', 'secure_api_key_10');

-- Create 1,000 links (100 per user)
WITH RECURSIVE link_numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n+1 FROM link_numbers
    LIMIT 1000
)
INSERT INTO links (user_id, slug, url)
SELECT
    ((n-1) % 10) + 1, -- User ID (1-10)
    'slug' || n,      -- Unique slug
    'https://sjdonado.com/page/' || n
FROM link_numbers;

-- Create 1,000,000 clicks (1,000 per link)
WITH RECURSIVE link_numbers(link_id) AS (
    SELECT id FROM links
),
click_batch(link_id, n) AS (
    SELECT link_id, 1 FROM link_numbers
    UNION ALL
    SELECT link_id, n+1 FROM click_batch WHERE n < 1000
)
INSERT INTO clicks (link_id, user_agent, browser, os, referer, country)
SELECT
    link_id,
    CASE (n % 5)
        WHEN 0 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
        WHEN 1 THEN 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)'
        WHEN 2 THEN 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0)'
        WHEN 3 THEN 'Mozilla/5.0 (X11; Linux x86_64)'
        ELSE 'Mozilla/5.0 (Android 11; Mobile)'
    END,
    CASE (n % 3)
        WHEN 0 THEN 'Chrome'
        WHEN 1 THEN 'Firefox'
        ELSE 'Safari'
    END,
    CASE (n % 4)
        WHEN 0 THEN 'Windows'
        WHEN 1 THEN 'macOS'
        WHEN 2 THEN 'iOS'
        ELSE 'Android'
    END,
    CASE (n % 6)
        WHEN 0 THEN 'https://sjdonado.com'
        WHEN 1 THEN 'https://donado.co'
        WHEN 2 THEN 'https://idonthavespotify.donado.co'
        WHEN 3 THEN 'https://spookyplanning.com'
        WHEN 4 THEN 'https://github.com/sjdonado'
        ELSE NULL
    END,
    CASE (n % 10)
        WHEN 0 THEN 'US'
        WHEN 1 THEN 'UK'
        WHEN 2 THEN 'Canada'
        WHEN 3 THEN 'Germany'
        WHEN 4 THEN 'France'
        WHEN 5 THEN 'Japan'
        WHEN 6 THEN 'Australia'
        WHEN 7 THEN 'Brazil'
        WHEN 8 THEN 'India'
        ELSE 'China'
    END
FROM click_batch;
