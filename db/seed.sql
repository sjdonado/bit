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

-- Create 1,000 clicks per link (10 million total)
WITH RECURSIVE counts(n) AS (
    SELECT 1
    UNION ALL
    SELECT n+1 FROM counts
    LIMIT 1000
)
INSERT INTO clicks (link_id, user_agent, browser, os, referer, country)
SELECT
    l.id,
    CASE (c.n % 5)
        WHEN 0 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
        WHEN 1 THEN 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)'
        WHEN 2 THEN 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0)'
        WHEN 3 THEN 'Mozilla/5.0 (X11; Linux x86_64)'
        ELSE 'Mozilla/5.0 (Android 11; Mobile)'
    END,
    CASE (c.n % 3)
        WHEN 0 THEN 'Firefox'
        WHEN 1 THEN 'Chrome'
        ELSE 'Safari'
    END,
    CASE (c.n % 4)
        WHEN 0 THEN 'macOS'
        WHEN 1 THEN 'Windows'
        WHEN 2 THEN 'iOS'
        ELSE 'Android'
    END,
    CASE (c.n % 6)
        WHEN 0 THEN 'https://sjdonado.com'
        WHEN 1 THEN 'https://donado.co'
        WHEN 2 THEN 'https://idonthavespotify.donado.co'
        WHEN 3 THEN 'https://spookyplanning.com'
        WHEN 4 THEN 'https://github.com/sjdonado'
        ELSE NULL
    END,
    CASE (c.n % 10)
        WHEN 0 THEN 'Colombia'
        WHEN 1 THEN 'Brazil'
        WHEN 2 THEN 'Canada'
        WHEN 3 THEN 'Germany'
        WHEN 4 THEN 'France'
        WHEN 5 THEN 'Japan'
        WHEN 6 THEN 'Australia'
        WHEN 7 THEN 'Brazil'
        WHEN 8 THEN 'India'
        ELSE 'China'
    END
FROM links l
CROSS JOIN counts c;
