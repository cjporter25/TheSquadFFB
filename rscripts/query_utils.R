library(DBI)
library(RSQLite)

# Standard pull of season pass attempts based on team
season_total_passes <- function(conn, season, team_abbr) {
  table_name <- paste0("pbp_", season)
  query <- sprintf(
    "SELECT COUNT(*) FROM %s WHERE posteam = '%s' AND play_type = 'pass'",
    table_name, team_abbr
  )
  result <- dbGetQuery(conn, query)
  result[[1]]
}

# Get count of completed passes based on season and team
season_total_completed_passes <- function(conn, season, team_abbr) {
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

season_passing_yardage_bd <- function(conn, season, team_abbr) {
  table_name <- paste0("pbp_", season)
  query <- sprintf(
    "SELECT game_id, posteam, play_type, yards_gained,
    passer_player_name, passing_yards, air_yards,
    receiver_player_name, receiving_yards, yards_after_catch,
    complete_pass, incomplete_pass
    FROM %s WHERE posteam = '%s' AND play_type = 'pass'",
    table_name, team_abbr
  )
  result <- dbGetQuery(conn, query)

  # Create a direct quick subset. Need to reference
  #   complete_pass's type from the data frame directly
  completed_passes <- subset(result, result$complete_pass == 1)
  incomplete_passes <- subset(result, result$incomplete_pass == 1)

  # === Yardage Buckets for Completed Passes ===
  completed_passes$yardage_group <- cut(
    completed_passes$yards_gained,
    breaks = c(-Inf, 5, 10, 15, 20, Inf),
    labels = c("0-4", "5-9", "10-14", "15-19", "20+"),
    right = FALSE  # So 10 goes into "10_14"
  )
  # === Create Yardage Buckets ===
  incomplete_passes$yardage_group <- cut(
    incomplete_passes$air_yards,
    breaks = c(-Inf, 5, 10, 15, 20, Inf),
    labels = c("0-4", "5-9", "10-14", "15-19", "20+"),
    right = FALSE  # So 10 goes into "10_20"
  )
  # === Preview Bucket Counts ===
  cat("\nCompleted Pass Distribution:\n")
  print(table(completed_passes$yardage_group))

  cat("\nIncomplete Pass Distribution:\n")
  print(table(incomplete_passes$yardage_group))
}

# Get count of incomplete passes based on season and team
season_total_incomplete_passes <- function(conn, season, team_abbr) {
  table_name <- paste0("pbp_", season)
  query <- sprintf(
    "SELECT COUNT(*) FROM %s WHERE posteam = '%s' 
    AND play_type = 'pass'
    AND complete_pass = '0'",
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

print_game_summary <- function(conn, season, team_abbr, game_id) {
  table_name <- paste0("pbp_", season)
  query <- sprintf(
    "SELECT game_id, posteam, play_type, yards_gained,
    passer_player_name, passing_yards, air_yards, pass_location,
    receiver_player_name, receiving_yards, yards_after_catch,
    complete_pass, incomplete_pass
    FROM %s
    WHERE posteam = '%s' AND play_type = 'pass' AND game_id = '%s'",
    table_name, team_abbr, game_id
  )
  result <- dbGetQuery(conn, query)
  incomplete <- subset(result, result$incomplete_pass == 1)
  print(result)
  print(incomplete)
}

# Print a team's season summary of calculated stats for visualizing primary
#   targets, percentages, etc.
# Output visuals will increase over time
print_season_summary <- function(conn, season, team_abbr) {
  num_passes <- season_total_passes(conn, season, team_abbr)
  num_comp_passes <- season_total_completed_passes(conn, season, team_abbr)
  num_incomp_passes <- season_total_incomplete_passes(conn, season, team_abbr)
  perc_completed_passes <- round((num_comp_passes / num_passes), 2)
  num_runs <- total_season_runs(conn, season, team_abbr)
  cat(sprintf("Team %s (%d):\n", team_abbr, season)
  )
  cat(sprintf(" Total Attempted Passes: %d\n", num_passes))
  cat(sprintf(" Completed Passes: %d\n", num_comp_passes))
  season_passing_yardage_bd(conn, season, team_abbr)
  cat(sprintf(" Incomplete Passes: %d\n", num_incomp_passes))
  cat(sprintf(" Percent Completed: %f\n", perc_completed_passes))
  cat(sprintf(" Runs: %d\n", num_runs))
}

print_every_season_summary <- function(conn, team_abbr, seasons = 2002:2024) {
  for (season in seasons) {
    table_name <- paste0("pbp_", season)

    if(table_name %in% dbListTables(conn)) {
      message(paste0("Season: ", season))
      print_season_summary(conn, season, team_abbr)
      cat("\n------------------------\n")
    } else {
      message(paste0("ERROR - Table for season ", season, " not found."))
    }
  }
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
