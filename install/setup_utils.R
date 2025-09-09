library(DBI)
library(RSQLite)
library(jsonlite)
library(nflreadr)

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

    # Save to SQLite
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
