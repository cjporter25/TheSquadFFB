library(DBI)
library(RSQLite)
# Use "source" when referencing other script files
source("rscripts/query_utils.R")


json_path <- "app_data.json"
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
  WHERE posteam = 'MIN' AND play_type = 'pass'
  ORDER BY game_id
")


# Create a direct quick subset
completed_passes <- subset(vikings_2024, complete_pass == 1)

# === Create Yardage Buckets ===
completed_passes$yardage_group <- cut(
  completed_passes$yards_gained,
  breaks = c(-Inf, 5, 10, 20, Inf),
  labels = c("0-4", "5-9", "10-19", "20+"),
  right = FALSE  # So 10 goes into "10_20"
)

# === Preview Bucket Counts ===
print(table(completed_passes$yardage_group))

# To confirm all necessary column names are there
names(completed_passes)
# Print all rows of a given query
# print_all_rows(completed_passes)

print_all_team_summaries(conn, 2024, json_path)

dbDisconnect(conn)
