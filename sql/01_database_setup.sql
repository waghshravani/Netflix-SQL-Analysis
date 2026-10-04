-- =============================================================
-- NETFLIX CONTENT ANALYSIS | Script 1 of 3: Setup & Data Load
-- Database : MySQL 8.0+
-- Purpose  : Create the database and tables, load the CSV files,
--            clean blank values, and add primary / foreign keys.
-- Run order: 01 -> 02 -> 03
-- =============================================================

CREATE DATABASE IF NOT EXISTS netflix;
USE netflix;

-- Makes the script re-runnable: drop child tables first, then the parent
DROP TABLE IF EXISTS netflix_viewership;
DROP TABLE IF EXISTS netflix_content_costs;
DROP TABLE IF EXISTS netflix;

-- -------------------------------------------------------------
-- 1. Create tables
-- -------------------------------------------------------------
CREATE TABLE netflix (
    show_id       VARCHAR(255),
    type          VARCHAR(255),
    title         VARCHAR(255),
    director      VARCHAR(255),
    `cast`        VARCHAR(1555),
    country       VARCHAR(255),
    date_added    VARCHAR(255),
    release_year  VARCHAR(255),
    rating        VARCHAR(255),
    duration      VARCHAR(255),
    listed_in     VARCHAR(1555),
    description   VARCHAR(1555)
);

CREATE TABLE netflix_viewership (
    show_id                 VARCHAR(255),
    type                    VARCHAR(255),
    release_year            INT,
    total_views_millions    INT,
    avg_watch_time_minutes  INT,
    peak_region             VARCHAR(255)
);

CREATE TABLE netflix_content_costs (
    show_id                        VARCHAR(255),
    type                           VARCHAR(255),
    production_cost_million_usd    INT,
    marketing_cost_million_usd     INT,
    estimated_revenue_million_usd  INT
);

-- -------------------------------------------------------------
-- 2. Load the main CSV file
-- Change the path to where the file is on YOUR machine.
-- Use forward slashes, even on Windows.
-- LOCAL INFILE must also be enabled on the client side
-- (MySQL Workbench: Edit Connection > Advanced > Others > OPT_LOCAL_INFILE=1).
-- If your CSV uses Windows line endings, use LINES TERMINATED BY '\r\n'.
-- -------------------------------------------------------------
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/path/to/netflix-sql-analysis/data/netflix.csv'
INTO TABLE netflix
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- -------------------------------------------------------------
-- 3. Data cleaning: LOAD DATA stores blank CSV cells as '' (not NULL),
--    which would break every "IS NOT NULL" filter in the analysis.
-- -------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE netflix
SET director   = NULLIF(TRIM(director), ''),
    `cast`     = NULLIF(TRIM(`cast`), ''),
    country    = NULLIF(TRIM(country), ''),
    date_added = NULLIF(TRIM(date_added), ''),
    rating     = NULLIF(TRIM(rating), '');

SET SQL_SAFE_UPDATES = 1;

-- -------------------------------------------------------------
-- 4. Primary key on the main table
-- -------------------------------------------------------------
ALTER TABLE netflix ADD CONSTRAINT PRIMARY KEY (show_id);

-- -------------------------------------------------------------
-- 5. Load the supporting tables
-- -------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/netflix-sql-analysis/data/netflix_viewership.csv'
INTO TABLE netflix_viewership
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/path/to/netflix-sql-analysis/data/netflix_content_costs.csv'
INTO TABLE netflix_content_costs
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- -------------------------------------------------------------
-- 6. Foreign keys (added after loading so bad data shows up as an error)
-- -------------------------------------------------------------
ALTER TABLE netflix_viewership
    ADD CONSTRAINT fk_viewership_show
    FOREIGN KEY (show_id) REFERENCES netflix (show_id);

ALTER TABLE netflix_content_costs
    ADD CONSTRAINT fk_costs_show
    FOREIGN KEY (show_id) REFERENCES netflix (show_id);

-- -------------------------------------------------------------
-- 7. Sanity checks
-- -------------------------------------------------------------
SELECT * FROM netflix LIMIT 10;

SELECT 'netflix'               AS table_name, COUNT(*) AS row_count FROM netflix
UNION ALL
SELECT 'netflix_viewership',                  COUNT(*)              FROM netflix_viewership
UNION ALL
SELECT 'netflix_content_costs',               COUNT(*)              FROM netflix_content_costs;
