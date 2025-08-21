# === Load Required Libraries ===
library(nflreadr)
library(DBI)
library(RSQLite)

# === Config ===
seasons <- 2014:2024
db_path <- "nfl_pbp.db"

# === Connect to (or create) SQLite database ===
conn <- dbConnect(SQLite(), db_path)

# === Loop through each season ===
for (year in seasons) {
  table_name <- paste0("pbp_", year)

  # Check if table already exists
  if (table_name %in% dbListTables(conn)) {
    message(paste0("Skipping ", year, ": already exists in database."))
    next
  }

  # Load data from nflreadr
  message(paste0("Loading play-by-play data for ", year, "..."))
  pbp <- load_pbp(year)
  pbp$season <- year  # Add season column

  # Save to SQLite
  message(paste0("Writing to table: ", table_name))
  dbWriteTable(conn, table_name, pbp, overwrite = TRUE)
}

# === Close DB connection ===
# dbDisconnect(conn)

message("✅ All seasons loaded and saved successfully.")

source("query_utils.R")

# conn <- connect_db()

# Example: list teams
teams <- get_teams_from_season(conn, 2023)
print(teams)

# Example: all 4th down passes by PHI
plays <- get_team_4th_down_passes(conn, 2023, "PHI")
head(plays)

# Example: distribution of play types for KC
summary <- get_play_type_counts(conn, 2022, "KC")
print(summary)

dbDisconnect(conn)
