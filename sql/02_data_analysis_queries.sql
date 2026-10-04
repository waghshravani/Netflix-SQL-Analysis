-- =============================================================
-- NETFLIX CONTENT ANALYSIS | Script 2 of 3: Analysis Queries (Q1-Q17)
-- Database : MySQL 8.0+
-- Sections : A) Core queries (Q1-Q15)   B) Advanced queries (Q16-Q17)
-- =============================================================

USE netflix;

-- =============================================================
-- A) CORE QUERIES
-- =============================================================

-- Q1. Count the number of Movies vs TV Shows
SELECT
    type,
    COUNT(*) AS total_content
FROM netflix
GROUP BY type;


-- Q2. Find the most common rating for Movies and TV Shows
WITH rating_count AS
(
    SELECT
        type,
        rating,
        COUNT(*) AS total_count
    FROM netflix
    WHERE rating IS NOT NULL
    GROUP BY type, rating
),
rating_rank AS
(
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY type ORDER BY total_count DESC) AS rnk
    FROM rating_count
)
SELECT
    type,
    rating,
    total_count
FROM rating_rank
WHERE rnk = 1;


-- Q3. List all movies released in a specific year (e.g., 2020)
SELECT *
FROM netflix
WHERE type = 'Movie'
  AND release_year = '2020';


-- Q4. Find the top 5 countries with the most content on Netflix
SELECT
    country,
    COUNT(*) AS total_content
FROM netflix
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;


-- Q5. Identify the longest movie
-- duration is stored as text (e.g. '90 min'), so the number is extracted first
SELECT
    title,
    duration
FROM netflix
WHERE type = 'Movie'
  AND duration IS NOT NULL
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;


-- Q6. Find content added in the last 5 years
-- The latest date in the dataset is the reference point instead of CURDATE(),
-- because the data is a historical snapshot.
SELECT *
FROM netflix
WHERE STR_TO_DATE(TRIM(date_added), '%M %d, %Y') >=
(
    SELECT DATE_SUB(MAX(STR_TO_DATE(TRIM(date_added), '%M %d, %Y')), INTERVAL 5 YEAR)
    FROM netflix
);


-- Q7. Find all movies / TV shows by director 'Rajiv Chilaka'
SELECT *
FROM netflix
WHERE director LIKE '%Rajiv Chilaka%';


-- Q8. List all TV shows with more than 5 seasons
SELECT
    title,
    duration
FROM netflix
WHERE type = 'TV Show'
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5;


-- Q9. Count the number of content items in each genre
-- Recursive CTE splits the comma-separated listed_in column into one row per genre
WITH RECURSIVE genre_split AS
(
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
        CASE
            WHEN listed_in LIKE '%,%'
            THEN SUBSTRING(listed_in, LOCATE(',', listed_in) + 1)
            ELSE ''
        END AS remaining
    FROM netflix
    WHERE listed_in IS NOT NULL
      AND listed_in <> ''

    UNION ALL

    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        CASE
            WHEN remaining LIKE '%,%'
            THEN SUBSTRING(remaining, LOCATE(',', remaining) + 1)
            ELSE ''
        END
    FROM genre_split
    WHERE remaining <> ''
)
SELECT
    genre,
    COUNT(*) AS total_content
FROM genre_split
WHERE genre <> ''
GROUP BY genre
ORDER BY total_content DESC;


-- Q10. For each year, find the share of India's Netflix content added that year.
--      Return the top 5 years.
SELECT
    YEAR(STR_TO_DATE(TRIM(date_added), '%M %d, %Y')) AS year_added,
    COUNT(*) AS content_count,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM netflix
            WHERE country LIKE '%India%'
              AND date_added IS NOT NULL
        ),
        2
    ) AS pct_of_india_content
FROM netflix
WHERE country LIKE '%India%'
  AND date_added IS NOT NULL
  AND STR_TO_DATE(TRIM(date_added), '%M %d, %Y') IS NOT NULL
GROUP BY YEAR(STR_TO_DATE(TRIM(date_added), '%M %d, %Y'))
ORDER BY pct_of_india_content DESC
LIMIT 5;


-- Q11. List all movies that are documentaries
SELECT *
FROM netflix
WHERE type = 'Movie'
  AND listed_in LIKE '%Documentaries%';


-- Q12. Find all content without a director
SELECT *
FROM netflix
WHERE director IS NULL
   OR TRIM(director) = '';


-- Q13. How many movies did actor 'Salman Khan' appear in during the last 10 years?
-- Note: uses CURDATE(), so the result depends on the date you run it.
SELECT
    COUNT(*) AS total_movies
FROM netflix
WHERE type = 'Movie'
  AND `cast` LIKE '%Salman Khan%'
  AND CAST(release_year AS UNSIGNED) >= YEAR(CURDATE()) - 10;


-- Q14. Find the top 10 actors with the most movies produced in India
WITH RECURSIVE actor_split AS
(
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(`cast`, ',', 1)) AS actor,
        CASE
            WHEN `cast` LIKE '%,%'
            THEN SUBSTRING(`cast`, LOCATE(',', `cast`) + 1)
            ELSE ''
        END AS remaining
    FROM netflix
    WHERE type = 'Movie'
      AND country LIKE '%India%'
      AND `cast` IS NOT NULL
      AND `cast` <> ''

    UNION ALL

    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        CASE
            WHEN remaining LIKE '%,%'
            THEN SUBSTRING(remaining, LOCATE(',', remaining) + 1)
            ELSE ''
        END
    FROM actor_split
    WHERE remaining <> ''
)
SELECT
    actor,
    COUNT(*) AS total_movies
FROM actor_split
WHERE actor <> ''
GROUP BY actor
ORDER BY total_movies DESC
LIMIT 10;


-- Q15. Label content as 'Bad' if its description contains 'kill' or 'violence',
--      otherwise 'Good'. Count how many items fall into each category.
SELECT
    CASE
        WHEN LOWER(description) LIKE '%kill%'
          OR LOWER(description) LIKE '%violence%'
        THEN 'Bad'
        ELSE 'Good'
    END AS content_category,
    COUNT(*) AS total_content
FROM netflix
GROUP BY content_category;


-- =============================================================
-- B) ADVANCED QUERIES (multi-table)
-- =============================================================

-- Q16. For each content type, find the top 3 most profitable titles released
--      after 2018, with their rank inside each type.
--      Profit = estimated_revenue - (production_cost + marketing_cost)
WITH profit_data AS
(
    SELECT
        n.show_id,
        n.title,
        n.type,
        n.release_year,
        c.estimated_revenue_million_usd
            - (c.production_cost_million_usd + c.marketing_cost_million_usd) AS profit_million_usd
    FROM netflix n
    JOIN netflix_content_costs c
        ON n.show_id = c.show_id
    WHERE CAST(n.release_year AS UNSIGNED) > 2018
),
profit_rank AS
(
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY type ORDER BY profit_million_usd DESC) AS profit_rank
    FROM profit_data
)
SELECT
    type,
    title,
    release_year,
    profit_million_usd,
    profit_rank
FROM profit_rank
WHERE profit_rank <= 3
ORDER BY type, profit_rank;


-- Q17. Among titles whose average watch time is above the platform average,
--      find the country with the highest total views and show its top title.
WITH above_avg_content AS
(
    SELECT
        n.show_id,
        n.title,
        n.country,
        v.total_views_millions,
        v.avg_watch_time_minutes
    FROM netflix n
    JOIN netflix_viewership v
        ON n.show_id = v.show_id
    WHERE v.avg_watch_time_minutes >
    (
        SELECT AVG(avg_watch_time_minutes)
        FROM netflix_viewership
    )
),
country_views AS
(
    SELECT
        country,
        SUM(total_views_millions) AS total_country_views
    FROM above_avg_content
    WHERE country IS NOT NULL
    GROUP BY country
),
top_country AS
(
    SELECT
        country,
        total_country_views
    FROM country_views
    ORDER BY total_country_views DESC
    LIMIT 1
),
title_rank AS
(
    SELECT
        a.country,
        a.title,
        a.total_views_millions,
        a.avg_watch_time_minutes,
        ROW_NUMBER() OVER (PARTITION BY a.country ORDER BY a.total_views_millions DESC) AS title_rank
    FROM above_avg_content a
    JOIN top_country t
        ON a.country = t.country
)
SELECT
    t.country,
    t.total_country_views,
    r.title                  AS top_contributing_title,
    r.total_views_millions   AS title_views,
    r.avg_watch_time_minutes
FROM top_country t
JOIN title_rank r
    ON t.country = r.country
WHERE r.title_rank = 1;
