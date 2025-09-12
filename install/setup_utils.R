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
