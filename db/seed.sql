INSERT INTO users (name, api_key)
VALUES
('User 1', 'secure_api_key_1'),
('User 2', 'secure_api_key_2');

-- Create 20,000 links (10,000 per user)
WITH RECURSIVE link_numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n+1 FROM link_numbers
    LIMIT 20000
)
INSERT INTO links (user_id, slug, url)
SELECT
    ((n-1) % 2) + 1, -- User ID (1-2)
    'slug' || n,      -- Unique slug
    'https://sjdonado.com/page/' || n
FROM link_numbers;

-- Create 1,000 clicks per link (20,000,000 total)
-- Using batched approach for better performance
CREATE TEMP TABLE link_ids AS SELECT id FROM links;

CREATE TEMP TABLE click_counts(link_id, count) AS
WITH RECURSIVE counts(n) AS (
    SELECT 1
    UNION ALL
    SELECT n+1 FROM counts
    LIMIT 1000
)
SELECT l.id, c.n
FROM link_ids l
CROSS JOIN counts c;

-- Insert clicks from the count table
INSERT INTO clicks (link_id, user_agent, browser, os, referer, country)
SELECT
    link_id,
    CASE (count % 5)
        WHEN 0 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
        WHEN 1 THEN 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)'
        WHEN 2 THEN 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0)'
        WHEN 3 THEN 'Mozilla/5.0 (X11; Linux x86_64)'
        ELSE 'Mozilla/5.0 (Android 11; Mobile)'
    END,
    CASE (count % 3)
        WHEN 0 THEN 'Chrome'
        WHEN 1 THEN 'Firefox'
        ELSE 'Safari'
    END,
    CASE (count % 4)
        WHEN 0 THEN 'Windows'
        WHEN 1 THEN 'macOS'
        WHEN 2 THEN 'iOS'
        ELSE 'Android'
    END,
    CASE (count % 6)
        WHEN 0 THEN 'https://sjdonado.com'
        WHEN 1 THEN 'https://donado.co'
        WHEN 2 THEN 'https://idonthavespotify.donado.co'
        WHEN 3 THEN 'https://spookyplanning.com'
        WHEN 4 THEN 'https://github.com/sjdonado'
        ELSE NULL
    END,
    CASE (count % 10)
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
FROM click_counts;

-- Clean up
DROP TABLE link_ids;
DROP TABLE click_counts;
