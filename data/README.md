# Data

Place the three CSV files in this folder before running `sql/01_database_setup.sql`:

- `netflix.csv`
- `netflix_viewership.csv`
- `netflix_content_costs.csv`

## netflix.csv (main catalogue)

| Column | Description |
|--------|-------------|
| show_id | Unique ID of the title (primary key) |
| type | Movie or TV Show |
| title | Title of the content |
| director | Director(s) |
| cast | Comma-separated list of actors |
| country | Country or countries of production |
| date_added | Date the title was added to Netflix (e.g. "September 25, 2021") |
| release_year | Original release year |
| rating | Content rating (e.g. TV-MA, PG-13) |
| duration | Minutes for movies, number of seasons for TV shows |
| listed_in | Comma-separated genres |
| description | Short synopsis |

## netflix_viewership.csv

| Column | Description |
|--------|-------------|
| show_id | Foreign key to netflix.show_id |
| type | Movie or TV Show |
| release_year | Release year |
| total_views_millions | Total views in millions |
| avg_watch_time_minutes | Average watch time per view, in minutes |
| peak_region | Region with the highest viewership |

## netflix_content_costs.csv

| Column | Description |
|--------|-------------|
| show_id | Foreign key to netflix.show_id |
| type | Movie or TV Show |
| production_cost_million_usd | Production cost (USD millions) |
| marketing_cost_million_usd | Marketing cost (USD millions) |
| estimated_revenue_million_usd | Estimated revenue (USD millions) |
