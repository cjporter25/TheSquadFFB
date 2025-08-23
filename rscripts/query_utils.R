library(DBI)
library(RSQLite)

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

# Print a team's season summary of calculated stats for visualizing primary
#   targets, percentages, etc.
# Output visuals will increase over time
print_season_summary <- function(conn, season, team_abbr) {
  num_passes <- total_season_passes(conn, season, team_abbr)
  num_completed_passes <- total_completed_season_passes(conn, season, team_abbr)
  perc_completed_passes <- round((num_completed_passes / num_passes), 2)
  num_runs <- total_season_runs(conn, season, team_abbr)
  cat(sprintf("Team %s (%d):\n Passes: %d\n Completed Passes: %d\n",
    team_abbr, season, num_passes, num_completed_passes
  )
  )
  cat(sprintf(" Percent Completed: %f\n", perc_completed_passes))
  cat(sprintf(" Runs: %d\n", num_runs))
}

# Print every team's season summaries
print_all_team_summaries <- function(conn, season, json_path) {
  if (!file.exists(json_path)) {
    stop("app_data.json not found.")
  }

  # Load the app_data.json
  app_data <- jsonlite::fromJSON(json_path)

  # Get the key name like "teams_2024"
  team_key <- paste0("teams_", season)

  # If the key doesn't exist, stop
  if (is.null(app_data[[team_key]])) {
    stop(paste0("No team data found for season: ", season))
  }

  # Extract the team list
  teams <- app_data[[team_key]]

  # Loop through each team and print the summary
  for (team in teams) {
    print_season_summary(conn, season, team)
    cat("\n---------------------------\n")
  }
}


print_all_rows <- function(df) {
  options(max.print = nrow(df) * ncol(df))
  print(df)
}
