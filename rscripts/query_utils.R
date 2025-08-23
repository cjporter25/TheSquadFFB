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

total_completed_season_passes <- function(conn, season, team_abbr) {
  table_name <- paste0("pbp_", season)
  query <- sprintf(
    "SELECT COUNT(*) FROM %s WHERE posteam = '%s' 
    AND play_type = 'pass'
    AND complete_pass = '1'",
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
# Get all unique team abbreviations from posteam column in 

# Print a team's season summary of calculated stats for visualizing primary
#   targets, percentages, etc.
# Output visuals will increase over time
print_season_summary <- function(conn, season, team_abbr) {
  num_passes <- total_season_passes(conn, season, team_abbr)
  num_completed_passes <- total_completed_season_passes(conn, season, team_abbr)
  num_runs <- total_season_runs(conn, season, team_abbr)
  cat(sprintf("Team %s (%d):\n Passes: %d\n Completed Passes: %d\n Runs: %d\n",
    team_abbr, season, num_passes, num_completed_passes, num_runs
  )
  )

}

print_all_rows <- function(df) {
  options(max.print = nrow(df) * ncol(df))
  print(df)
}
