library(DBI)
library(RSQLite)

# Connect to DB (call this once)
connect_db <- function(db_path = "nfl_pbp.db") {
  dbConnect(SQLite(), db_path)
}

# Standard pull of season pass attempts based on team
total_season_passes <- function(conn, season, team_abbr) {
  table_name <- paste0("pbp_", season)
  query <- sprintf(
    "SELECT COUNT(*) FROM %s WHERE posteam = '%s' AND play_type = 'pass'",
    table_name, team_abbr
  )
  result <- dbGetQuery(conn, query)
  result[[1]]
}
# Standard pull of season run attempts based on team
total_season_runs <- function(conn, season, team_abbr) {
  table_name <- paste0("pbp_", season)
  query <- sprintf(
    "SELECT COUNT(*) FROM %s WHERE posteam = '%s' AND play_type = 'run'",
    table_name, team_abbr
  )
  result <- dbGetQuery(conn, query)
  result[[1]]
}

# Print a team's season summary of calculated stats for visualizing primary
#   targets, percentages, etc.
# Output visuals will increase over time
print_season_summary <- function(conn, season, team_abbr) {
  num_passes <- total_season_passes(conn, season, team_abbr)
  num_runs <- total_season_runs(conn, season, team_abbr)
  cat(sprintf("Team %s (%d): %d passes, %d runs\n",
    team_abbr, season, num_passes, num_runs
  )
  )

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

print_all_rows <- function(df) {
  options(max.print = nrow(df) * ncol(df))
  print(df)
}


