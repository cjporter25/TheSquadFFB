library(DBI)
library(RSQLite)
library(jsonlite)
# package contains multiple instances of the same function,
#   this will prevent the startup messages that indicate this
suppressPackageStartupMessages(library(dplyr))

assign("JSON_PATH", "app_data.json", envir = .GlobalEnv)

# Retrieve a list of game_ids for every time two teams have played each other
get_historical_matches <- function(conn, num_years, team_one, team_two) {
  curr_year <- 2024
  matches_df <- list()
  matches_list <- c() # Empty character vector (for final list)

  for (i in 0:(num_years - 1)) {
    season <- curr_year - i
    table_name <- paste0("pbp_", season)
    validate_input(season, team_one, JSON_PATH)
    validate_input(season, team_two, JSON_PATH)
    # 1. Find all plays where the posession team is either team one or team two
    # 2. Confirm both teams are only either on off/def or def/off
    query <- sprintf(
      "SELECT DISTINCT game_id
      FROM %s 
      WHERE (posteam = '%s' AND defteam = '%s')
      OR (posteam = '%s' and defteam = '%s')",
      table_name, team_one, team_two, team_two, team_one
    )

    result <- dbGetQuery(conn, query)
    # Create a list of data frames by year, then game_id's
    #   in that year
    matches_df[[as.character(season)]] <- result

    # If there are matches for that year pull the values
    #   associated with the game_id column
    if (nrow(result) > 0) {
      matches_list <- c(matches_list, result$game_id)
    }
  }
  # Return the full matches list
  matches_list
}
get_historical_match_stats <- function(conn, num_years, team_one, team_two) {
  matches <- get_historical_matches(conn, num_years, team_one, team_two)
  for (game_id in matches){
    table_name <- paste0("pbp_", substr(game_id, 1, 4))
    query <- sprintf(
      "SELECT game_id, posteam, play_type, yards_gained,
      rusher_player_name, rushing_yards, rush_attempt,
      passer_player_name, passing_yards, air_yards, pass_location,
      receiver_player_name, receiving_yards, yards_after_catch,
      complete_pass, incomplete_pass
      FROM %s
      WHERE game_id = '%s'",
      table_name, game_id
    )
    result <- dbGetQuery(conn, query)
    cat("      Game ID: ", game_id, "\n")
    team_one_passes <- result %>%
      filter(.data$posteam == team_one, .data$play_type == "pass")
    team_one_runs <- result %>%
      filter(.data$posteam == team_one, .data$play_type == "run")
    team_two_passes <- result %>%
      filter(.data$posteam == team_two, .data$play_type == "pass")
    team_two_runs <- result %>%
      filter(.data$posteam == team_two, .data$play_type == "run")

    t_one_pass_stats <- calc_match_pass_stats(team_one_passes)
    calc_match_run_stats(team_one_runs)
    t_two_pass_stats <- calc_match_pass_stats(team_two_passes)
    calc_match_run_stats(team_two_runs)

    print_side_by_side(team_one, t_one_pass_stats, team_two, t_two_pass_stats)
  }
}

calc_match_pass_stats <- function(passes) {
  # Count all pass attempts
  num_attempts <- nrow(passes)

  comp_passes <- subset(passes, passes$complete_pass == 1)
  num_comp <- nrow(comp_passes)

  total_p_yards <- sum(comp_passes$yards_gained, na.rm = TRUE)

  incomp_passes <- subset(passes, passes$incomplete_pass == 1)
  num_incomp <- nrow(incomp_passes)

  perc_complete <- if (num_attempts > 0) {
    # Format forces a decimal even if it's zero
    formatC((num_comp / num_attempts) * 100, format = "f", digits = 1)
  } else {
    NA
  }
  # Return all stats as a named list
  list(
    num_attempts = num_attempts,
    total_p_yards = total_p_yards,
    num_comp = num_comp,
    num_incomp = num_incomp,
    perc_complete = perc_complete
  )
}
calc_match_run_stats <- function(runs) {
  # Count all run attempts
  num_attempts <- nrow(runs)

  list(
    num_attempts = num_attempts
  )
}

print_side_by_side <- function(team_one_abbr, t_one, team_two_abbr, t_two) {
  cat("         Team: ", team_one_abbr, team_two_abbr, "\n")
  cat("Pass Attempts: ", t_one$num_attempts, " ", t_two$num_attempts, "\n")
  cat("Total P Yards: ", t_one$total_p_yards, "", t_two$total_p_yards, "\n")
  cat("  Comp Passes: ", t_one$num_comp, " ", t_two$num_comp, "\n")
  cat("Incomp Passes: ", t_one$num_incomp, " ", t_two$num_incomp, "\n")
  cat(" Completion %: ", t_one$perc_complete, t_two$perc_complete, "\n")
}

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

season_get_all_passes <- function(conn, season, team_abbr) {
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
  result
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
  # Retrieve the value at index 1, which is the count result
  result[[1]]
}

season_passing_yardage_bd <- function(conn, season, team_abbr) {

  result <- season_get_all_passes(conn, season, team_abbr)

  # === Combine Yardage Values Based on Completion Status ===
  result$attempted_yards <- ifelse(
    result$complete_pass == 1,
    result$yards_gained, # if complete, use yards_gained
    result$air_yards # if not complete, user air_yards
  )

  # Create a direct quick subset. Need to reference
  #   complete_pass's type from the data frame directly
  completed_passes <- subset(result, result$complete_pass == 1)
  incomplete_passes <- subset(result, result$incomplete_pass == 1)

  # === Yardage Buckets for all Pass Attempts ===
  result$attempted_group <- cut(
    result$attempted_yards,
    breaks = c(-Inf, 5, 10, 15, 20, Inf),
    labels = c("0-4", "5-9", "10-14", "15-19", "20+"),
    right = FALSE
  )

  # === Yardage Buckets for Completed Passes ===
  completed_passes$yardage_group <- cut(
    completed_passes$yards_gained,
    breaks = c(-Inf, 5, 10, 15, 20, Inf),
    labels = c("0-4", "5-9", "10-14", "15-19", "20+"),
    right = FALSE  # So 10 goes into "10_14"
  )
  # === Yardage Buckets for Incomplete Passes ===
  incomplete_passes$yardage_group <- cut(
    incomplete_passes$air_yards,
    breaks = c(-Inf, 5, 10, 15, 20, Inf),
    labels = c("0-4", "5-9", "10-14", "15-19", "20+"),
    right = FALSE  # So 10 goes into "10_20"
  )

  # === Attempted Pass Distribution ===
  combined_counts <- table(factor(
    c(completed_passes$yardage_group, incomplete_passes$yardage_group),
    levels = c("0-4", "5-9", "10-14", "15-19", "20+")
  ))
  # === Completion Percentage (efficiency at each depth) ===
  yardage_groups <- c("0-4", "5-9", "10-14", "15-19", "20+")
  completed_counts <- table(
    factor(
      completed_passes$yardage_group,
      levels = yardage_groups
    )
  )
  # === Propensity to Attempt by Yardage Group ===
  attempt_counts <- table(factor(
    result$attempted_group,
    levels = yardage_groups
  ))

  # Calc completion percentage per yardage group
  completion_rates <- round((completed_counts / combined_counts) * 100, 1)
  completion_rates[is.na(completion_rates)] <- 0

  total_attempts <- sum(attempt_counts)
  # Calc percentage of each yardage group against the total
  py_prop <- round((attempt_counts / total_attempts) * 100, 1)

  # === Top Receiver by Yardage Group (Completed Passes) ===
  #   Take the df of completed_passes and apply (in-order)
  #   the following transformations
  top_receivers <- completed_passes %>%
    # Filter out instances where data is missing (NA)
    filter(!is.na(.data$receiver_player_name)) %>%
    # Group by yardage_group and player name
    #   i.e. all 0-4 hockenson passes are one group, and all
    #   jefferson 10-14 yard passes are another, etc.
    group_by(.data$yardage_group, .data$receiver_player_name) %>%
    # Creates a column for the count of entries per group
    tally(sort = TRUE) %>%
    # When n = 1, for each bucket, pick the single receiver with the
    #   highest number of receptions. When n = 2, the top two, etc.
    slice_max(n, n = 1) %>%
    # Remove grouping logic just in case
    ungroup()

  list(
    attempted_group = result$attempted_group,
    py_prop = py_prop,
    completed_passes = completed_passes,
    incomplete_passes = incomplete_passes,
    completion_rates = completion_rates,
    top_receivers = top_receivers
  )
}

season_favorite_rec_targets <- function(conn, season, team_abbr) {

  result <- season_get_all_passes(conn, season, team_abbr)
  # Filter out rows with NA receiver names (just in case)
  result <- result[!is.na(result$receiver_player_name), ]
  # Count # of times a receiver shows up
  receiver_counts <- as.data.frame(table(result$receiver_player_name))
  # Rename columns
  colnames(receiver_counts) <- c("Name", "Targets")
  # Order by # of targets and get top 5. Using "-" to indicate
  #   smallest row number first
  top_targets <- receiver_counts[order(-receiver_counts$Targets), ][1:5, ]
  # Return as tibble so the row numbering is 1-5
  as_tibble(top_targets)
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
print_season_summary <- function(conn, season, team_abbr, json_path) {

  if (!(validate_input(season, team_abbr, json_path))) {
    stop("Unable to print team summary, issue with input ^")
  }

  num_passes <- season_total_passes(conn, season, team_abbr)
  num_comp_passes <- season_total_completed_passes(conn, season, team_abbr)
  num_incomp_passes <- season_total_incomplete_passes(conn, season, team_abbr)
  # Only affects internal numeric precision, not what can be printed
  perc_completed_passes <- round((num_comp_passes / num_passes), 2)
  num_runs <- total_season_runs(conn, season, team_abbr)
  pass_dists <- season_passing_yardage_bd(conn, season, team_abbr)
  fav_rec_targets <- season_favorite_rec_targets(conn, season, team_abbr)

  cat(sprintf("Team %s (%d):\n", team_abbr, season)
  )
  cat(sprintf(" Total Attempted Passes: %d\n", num_passes))
  cat(sprintf(" Completed Passes: %d\n", num_comp_passes))
  cat(sprintf(" Incomplete Passes: %d\n", num_incomp_passes))
  # Format the string to print with only 2 digits
  cat(sprintf(" Percent Completed: %.2f\n", perc_completed_passes))
  cat(sprintf(" Runs: %d\n", num_runs))
  cat("\nAttempted (", season, ") Pass Distribution:\n", sep = "")
  print(table(pass_dists$attempted_group))
  cat("\nAttempt Propensity by Yardage Group:\n")
  for (group in names(pass_dists$py_prop)) {
    cat(sprintf("  %s: %.1f%%\n", group, pass_dists$py_prop[group]))
  }
  cat("\nCompleted (", season, ") Pass Distribution:\n")
  print(table(pass_dists$completed_passes$yardage_group))
  cat("\nIncomplete (", season, ") Pass Distribution:\n")
  print(table(pass_dists$incomplete_passes$yardage_group))
  cat(sprintf("\nCompletion %% by Yardage Group:\n"))
  for (group in names(pass_dists$completion_rates)) {
    cat(sprintf("  %s: %.1f%%\n", group, pass_dists$completion_rates[group]))
  }
  cat("\nTop Receiver per Yardage Group (Completed Passes):\n")
  for (i in seq_len(nrow(pass_dists$top_receivers))) {
    cat("Yardage Group:",
        as.character(pass_dists$top_receivers$yardage_group[i]),
        "\n| Player:", pass_dists$top_receivers$receiver_player_name[i],
        "\n| Completions:", pass_dists$top_receivers$n[i], "\n")
  }
  cat("\nFavorite Targets (", season, ") :\n")
  print(fav_rec_targets)
  cat("\n#1 Target (", season, "): ",
      as.character(fav_rec_targets$Name[1]), " - ",
      fav_rec_targets$Targets[1], "\n")
}

print_every_season_summary <- function(conn, team_abbr, seasons = 2002:2024) {
  for (season in seasons) {
    table_name <- paste0("pbp_", season)

    if (table_name %in% dbListTables(conn)) {
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

validate_input <- function(season, team_abbr, json_path) {
  # Ensure year is numeric or a string of digits
  if (!grepl("^\\d{4}$", season)) {
    # Halts execution and prints a statement
    stop("Year must be a 4-digit string or numeric value.")
  }

  # Load the JSON file
  data <- fromJSON(json_path)

  # Create the lookup key
  key <- paste0("teams_", season)

  # Check if the key (year) exists in app_data
  if (!(key %in% names(data))) {
    stop(paste("Year", season, "is not supported in the dataset."))
  }

  # Check if the team abbreviation is valid for that year
  if (!(team_abbr %in% data[[key]])) {
    stop(paste("Team abbreviation", team_abbr, "is not valid for year", season))
  }

  # If both checks pass, return TRUE
  TRUE
}
