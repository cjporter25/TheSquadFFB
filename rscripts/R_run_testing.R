library(DBI)
library(RSQLite)
# Use "source" when referencing other script files
source("rscripts/query_utils.R")

conn <- dbConnect(SQLite(), "nfl_pbp.db")

vikings_2024 <- dbGetQuery(conn, "
  SELECT
    game_id,
    play_type,
    yards_gained,
    passer_player_name,
    passing_yards,
    receiver_player_name,
    receiving_yards,
    complete_pass
  FROM pbp_2024
  WHERE posteam = 'MIN' AND play_type = 'pass' AND game_id = '2024_01_MIN_NYG'
  ORDER BY game_id
")


# Create a direct quick subset
completed_passes <- subset(vikings_2024, complete_pass == 1)

# === Create Yardage Buckets ===
completed_passes$yardage_group <- cut(
  completed_passes$yards_gained,
  breaks = c(-Inf, 5, 10, 20, Inf),
  labels = c("very_short", "short_pass", "mid_pass", "long_pass"),
  right = FALSE  # So 10 goes into "10_20"
)

# === Preview Bucket Counts ===
print(table(completed_passes$yardage_group))
# nrow(vikings_2024)
# To confirm all necessary column names are there
names(completed_passes)
# Print all rows of a given query
print_all_rows(completed_passes)

print_season_summary(conn, 2024, "MIN")

dbDisconnect(conn)
