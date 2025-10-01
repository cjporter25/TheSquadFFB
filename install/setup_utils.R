library(DBI)
library(RSQLite)
library(jsonlite)
library(nflreadr)
library(dplyr)

# Load from 2002 since that has all of the current teams
load_and_save_pbp_seasons <- function(conn, seasons = 2002:2025) {
  # Loop through seasons
  for (year in seasons) {
    table_name <- paste0("pbp_", year)

    if (table_name %in% dbListTables(conn)) {
      message(paste0("Skipping ", year, ": already exists in database."))
      next
    }

    # Load the PBP data
    message(paste0("Loading play-by-play data for ", year, "..."))
    pbp <- load_pbp(year)
    pbp$season <- year  # Add explicit season column

    # Save to db
    message(paste0("Writing to table: ", table_name))
    dbWriteTable(conn, table_name, pbp, overwrite = TRUE)
  }
  message("✅ All missing seasons loaded and saved successfully.")
}

update_team_list_json <- function(conn, json_path) {

  # List all tables in the DB
  tables <- dbListTables(conn)

  # Load or initialize app_data
  if (file.exists(json_path)) {
    app_data <- fromJSON(json_path)
  } else {
    app_data <- list()
  }

  seasons_found <- c()

  # Loop through each PBP table. Ensure the table name matches
  #     the intended schema
  for (table_name in tables) {
    if (grepl("^pbp_\\d{4}$", table_name)) {
      season_year <- sub("pbp_", "", table_name)
      season_key <- paste0("teams_", season_year)
      seasons_found <- c(seasons_found, season_year)

      # Skip if already recorded
      if (!is.null(app_data[[season_key]])) next

      # Query unique non-null team names
      query <- sprintf("
        SELECT DISTINCT posteam
        FROM %s
        WHERE posteam IS NOT NULL AND posteam <> ''
        ORDER BY posteam
      ", table_name)

      teams <- dbGetQuery(conn, query)$posteam

      # Store in app_data
      app_data[[season_key]] <- unique(teams)
    }
  }

  # Save JSON to disk
  write_json(app_data, json_path, pretty = TRUE, auto_unbox = TRUE)

  cat(sprintf("✅ Team list updated in %s\n", json_path))
}

save_team_pbps <- function(main_conn, team_conn, app_data_path) {
  # === Load app_data.json ===
  team_seasons <- fromJSON(app_data_path)

  # === Loop over each season and team in app_data.json ===
  for (season in names(team_seasons)) {
    # Extrapolate the year in question from the scheme in app_data
    #     i.e., if the list is teams_2024, year = 2024
    year <- gsub("teams_", "", season)
    table_name <- paste0("pbp_", year)

    if (!dbExistsTable(main_conn, table_name)) {
      cat("Skipping missing table:", table_name, "\n")
      next
    }

    for (team in team_seasons[[season]]) {
      cat("Processing", team, "for season", year, "\n")

      query <- sprintf(
        "SELECT *
        FROM %s
        WHERE posteam = '%s'
            OR defteam = '%s'
            OR game_id LIKE '%%%s%%'",
        table_name, team, team, team
      )

      # Get all plays where the team was involved
      team_data <- dbGetQuery(main_conn, query)

      # Append to table (or create new if doesn't exist)
      if (dbExistsTable(team_conn, paste0(team, "_pbp"))) {
        dbAppendTable(team_conn, paste0(team, "_pbp"), team_data)
      } else {
        dbWriteTable(team_conn, paste0(team, "_pbp"), team_data)
      }
    }
  }

  cat("✅ Team-specific PBP tables written to nfl_team_pbp.db\n")
}

save_new_team_pbps <- function(main_conn, team_conn, app_data_path, curr_year) {
  # === Load app_data.json ===
  team_seasons <- fromJSON(app_data_path)

  # === Loop over each season and team in app_data.json ===
  for (season in names(team_seasons)) {
    # Extrapolate the year in question from the scheme in app_data
    #     i.e., if the list is teams_2024, year = 2024
    year <- gsub("teams_", "", season)
    if (year != curr_year) {
      next
    }
    table_name <- paste0("pbp_", year)

    if (!dbExistsTable(main_conn, table_name)) {
      cat("Skipping missing table:", table_name, "\n")
      next
    }

    for (team in team_seasons[[season]]) {
      cat("Processing", team, "for season", year, "\n")

      query <- sprintf(
        "SELECT *
        FROM %s
        WHERE posteam = '%s'
            OR defteam = '%s'
            OR game_id LIKE '%%%s%%'",
        table_name, team, team, team
      )

      # Get all plays where the team was involved
      team_data <- dbGetQuery(main_conn, query)

      # Append to table (or create new if doesn't exist)
      if (dbExistsTable(team_conn, paste0(team, "_pbp"))) {
        dbAppendTable(team_conn, paste0(team, "_pbp"), team_data)
      } else {
        dbWriteTable(team_conn, paste0(team, "_pbp"), team_data)
      }
    }
  }

  cat("✅ Team-specific PBP tables written to nfl_team_pbp.db\n")
}

# Iterate through each season's team list and calculate summaries
save_team_summs <- function(main_conn, team_conn, ss_conn, json_path) {
  if (!file.exists(json_path)) {
    stop("app_data.json not found.")
  }
  app_data <- jsonlite::fromJSON(json_path)
  seasons <- 2002:2025
  for (season in seasons) {
    key <- paste0("teams_", season)
    teams <- app_data[[key]]
    for (team in teams) {
      summ <- get_season_off_summ(main_conn, team_conn, season, team)
      save_team_off_summ(summ, ss_conn)
      cat("✅ ", season, "", team, "summary saved to nfl_team_ss.db\n")
    }
  }
}

# Iterate through each season's team list and calculate summaries
save_team_summs_new <- function(main_conn, team_conn, ss_conn, json_path) {
  if (!file.exists(json_path)) {
    stop("app_data.json not found.")
  }
  app_data <- jsonlite::fromJSON(json_path)
  seasons <- 2025:2025
  for (season in seasons) {
    key <- paste0("teams_", season)
    teams <- app_data[[key]]
    for (team in teams) {
      summ <- get_season_off_summ(main_conn, team_conn, season, team)
      save_team_off_summ(summ, ss_conn)
      cat("✅ ", season, "", team, "summary saved to nfl_team_ss.db\n")
    }
  }
}

# Gather and save specific team season summary
save_team_off_summ <- function(summ, ss_conn) {
  season <- summ$season
  team_abbr <- summ$team_abbr
  table_name <- paste0(season, "_ts")

  # Grab only non-table values for now
  single_vals <- summ[sapply(summ, function(x) length(x) == 1)]
  single_vals$season <- as.character(single_vals$season)

  # Create one row data frame from incoming table to insert into db
  df <- as.data.frame(single_vals, optional = TRUE)

  # Append or create table to account for initial edge case
  if (!DBI::dbExistsTable(ss_conn, table_name)) {
    message("creating new table")
    DBI::dbWriteTable(ss_conn, table_name, df, overwrite = FALSE)
  } else {
    # If table already exists, check for whether the team was already added
    existing_team <- DBI::dbGetQuery(
      ss_conn,
      # Apparently need to quote the table_name cause SQL doesn't
      #   like it starting with a number
      paste0('SELECT 1 FROM "', table_name, '" WHERE team_abbr = ? LIMIT 1'),
      params = list(team_abbr)
    )
    # If query result is empty, it's nrow size will be zero
    if (nrow(existing_team) > 0) {
      # Check whether we're working with current season
      if (season == 2025) {
        # Overwrite row to account for potential new data in 2025
        DBI::dbExecute(
          ss_conn,
          paste0('DELETE FROM "', table_name, '" WHERE team_abbr = ?'),
          params = list(team_abbr)
        )
        DBI::dbWriteTable(ss_conn, table_name, df, append = TRUE)
        message("🔄 Refreshing data for: ", team_abbr)
      } else {
        message("Skipped (already exists): ", team_abbr)
      }
    } else {
      DBI::dbWriteTable(ss_conn, table_name, df, append = TRUE)
      message("✅ Appended new row: ", team_abbr)
    }
  }
}

# Find and calculate basic summary stats (passes/runs/etc)
get_season_off_summ <- function(main_conn, team_conn, season, team_abbr) {
  table_name <- paste0(team_abbr, "_pbp")
  query <- sprintf(
    "SELECT game_id, posteam, defteam, play_type, yards_gained,
    rusher_player_name, rushing_yards, rush_attempt,
    passer_player_name, passing_yards, air_yards,
    receiver_player_name, receiving_yards, yards_after_catch,
    complete_pass, incomplete_pass
    FROM %s WHERE season = '%s'",
    table_name, season
  )
  result <- dbGetQuery(team_conn, query)

  # ALl designed Pass plays
  passes <- subset(result, result$play_type == "pass"
                   & result$posteam == team_abbr)
  num_p_attempted <- nrow(passes)

  comp_p <- subset(passes, passes$complete_pass == 1)
  num_comp_p <- nrow(comp_p)
  total_comp_p_yds <- sum(comp_p$yards_gained, na.rm = TRUE)

  incomp_p <- subset(passes, passes$incomplete_pass == 1)
  num_incomp_p <- nrow(incomp_p)

  perc_comp_p <- round((num_comp_p / num_p_attempted) * 100, 1)

  pass_dists <- get_passing_yardage_bd(main_conn, season, team_abbr, 1)

  # All designed run plays
  runs <- subset(result, result$play_type == "run"
                 & result$posteam == team_abbr)

  r_for_gain <- subset(runs, runs$yards_gained > 0)
  num_r_for_gain <- nrow(r_for_gain)
  total_r_gain <- sum(r_for_gain$yards_gained, na.rm = TRUE)

  r_for_loss <- subset(runs, runs$yards_gained < 0)
  num_r_for_loss <- nrow(r_for_loss)
  total_r_loss <- sum(r_for_loss$yards_gained, na.rm = TRUE)

  num_r_attempted <- nrow(runs)
  total_r_yds <- sum(runs$yards_gained, na.rm = TRUE)
  list(
    team_abbr = team_abbr,
    season = season,
    num_p_attempted = num_p_attempted,
    attempted_group = table(pass_dists$attempted_group),
    num_comp_p = num_comp_p,
    comp_group = table(pass_dists$completed_passes$yardage_group),
    num_incomp_p = num_incomp_p,
    total_comp_p_yds = total_comp_p_yds,
    incomp_group = table(pass_dists$incomplete_passes$yardage_group),
    perc_comp_p = perc_comp_p,
    num_r_attempted = num_r_attempted,
    total_r_yds = total_r_yds,
    num_r_for_gain = num_r_for_gain,
    total_r_gain = total_r_gain,
    num_r_for_loss = num_r_for_loss,
    total_r_loss = total_r_loss
  )
}
get_passing_yardage_bd <- function(conn, season, team_abbr, poss_flag) {

  if (poss_flag == 1) {
    result <- season_get_all_passes_off(conn, season, team_abbr)
  } else {
    result <- season_get_all_passes_def(conn, season, team_abbr)
  }

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
    right = FALSE  # So 10 goes into "10_14"
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

# Retrieve specific set of passing plays for yardage breakdown
season_get_all_passes_off <- function(conn, season, team_abbr) {
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
# Retrieve specific set of passing plays for yardage breakdown
season_get_all_passes_def <- function(conn, season, team_abbr) {
  table_name <- paste0("pbp_", season)
  query <- sprintf(
    "SELECT game_id, defteam, play_type, yards_gained,
    passer_player_name, passing_yards, air_yards,
    receiver_player_name, receiving_yards, yards_after_catch,
    complete_pass, incomplete_pass
    FROM %s WHERE defteam = '%s' AND play_type = 'pass'",
    table_name, team_abbr
  )

  result <- dbGetQuery(conn, query)
  result
}