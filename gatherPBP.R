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
dbDisconnect(conn)

message("✅ All seasons loaded and saved successfully.")
