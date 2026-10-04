-- =============================================================
-- NETFLIX CONTENT ANALYSIS | Script 3 of 3: Business Insights
-- Database : MySQL 8.0+
-- Goal     : Answer business questions that combine content,
--            viewership and cost/revenue data.
-- =============================================================

USE netflix;

-- B1. Which content type is more profitable? (Movie vs TV Show)
SELECT
    n.type,
    ROUND(AVG(
        c.estimated_revenue_million_usd
        - (c.production_cost_million_usd + c.marketing_cost_million_usd)
    ), 2) AS avg_profit_million_usd
FROM netflix n
JOIN netflix_content_costs c
    ON n.show_id = c.show_id
GROUP BY n.type;


-- B2. Which genres generate the highest views? (top 5)
-- Every genre of a title is counted (recursive split of listed_in)
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
    g.genre,
    SUM(v.total_views_millions) AS total_views_millions
FROM genre_split g
JOIN netflix_viewership v
    ON g.show_id = v.show_id
WHERE g.genre <> ''
GROUP BY g.genre
ORDER BY total_views_millions DESC
LIMIT 5;


-- B3. Is a higher budget always more profitable?
SELECT
    CASE
        WHEN production_cost_million_usd < 50 THEN 'Low Budget (<50M)'
        WHEN production_cost_million_usd BETWEEN 50 AND 100 THEN 'Medium Budget (50-100M)'
        ELSE 'High Budget (>100M)'
    END AS budget_category,
    COUNT(*) AS titles,
    ROUND(AVG(
        estimated_revenue_million_usd
        - (production_cost_million_usd + marketing_cost_million_usd)
    ), 2) AS avg_profit_million_usd
FROM netflix_content_costs
GROUP BY budget_category;


-- B4. Which countries have the highest engagement (average watch time)? (top 5)
SELECT
    n.country,
    ROUND(AVG(v.avg_watch_time_minutes), 2) AS avg_watch_time_minutes
FROM netflix n
JOIN netflix_viewership v
    ON n.show_id = v.show_id
WHERE n.country IS NOT NULL
GROUP BY n.country
ORDER BY avg_watch_time_minutes DESC
LIMIT 5;


-- B5. Top 5 most successful titles (ranked by views, profit shown alongside)
SELECT
    n.title,
    v.total_views_millions,
    c.estimated_revenue_million_usd
        - (c.production_cost_million_usd + c.marketing_cost_million_usd) AS profit_million_usd
FROM netflix n
JOIN netflix_viewership v
    ON n.show_id = v.show_id
JOIN netflix_content_costs c
    ON n.show_id = c.show_id
ORDER BY v.total_views_millions DESC, profit_million_usd DESC
LIMIT 5;


-- B6. Do higher-rated (more mature) titles get more views? Average views by rating
SELECT
    n.rating,
    COUNT(*) AS titles,
    ROUND(AVG(v.total_views_millions), 2) AS avg_views_millions
FROM netflix n
JOIN netflix_viewership v
    ON n.show_id = v.show_id
WHERE n.rating IS NOT NULL
GROUP BY n.rating
ORDER BY avg_views_millions DESC;
