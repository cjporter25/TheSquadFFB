library(DBI)
library(RSQLite)

# Connect to DB (call this once)
connect_db <- function(db_path = "nfl_pbp.db") {
  dbConnect(SQLite(), db_path)
}

# Get all unique teams from a given year
get_teams_from_season <- function(conn, year) {
  tbl_name <- paste0("pbp_", year)
  dbGetQuery(conn, paste0("SELECT DISTINCT posteam FROM ", tbl_name, " WHERE posteam IS NOT NULL"))
}

# Get all 4th down passing plays for a team
get_team_4th_down_passes <- function(conn, year, team_abbr) {
  tbl_name <- paste0("pbp_", year)
  query <- sprintf(
    "SELECT * FROM %s WHERE posteam = '%s' AND down = 4 AND play_type = 'pass'",
    tbl_name, team_abbr
  )
  dbGetQuery(conn, query)
}

# Get total plays by type for a team
get_play_type_counts <- function(conn, year, team_abbr) {
  tbl_name <- paste0("pbp_", year)
  query <- sprintf(
    "SELECT play_type, COUNT(*) AS count FROM %s WHERE posteam = '%s' GROUP BY play_type ORDER BY count DESC",
    tbl_name, team_abbr
  )
  dbGetQuery(conn, query)
}


