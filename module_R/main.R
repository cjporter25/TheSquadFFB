library(DBI)
library(RSQLite)
# Use "source" when referencing other script files
source("module_R/query_utils.R")


json_path <- "app_data.json"
conn <- dbConnect(SQLite(), "nfl_pbp.db")

start <- Sys.time()
#-------------------------------------------------------------#
# season_passing_yardage_bd(conn, 2022, "MIN")
# season_passing_yardage_bd(conn, 2023, "MIN")
# season_passing_yardage_bd(conn, 2024, "MIN")
print_season_summary(conn, 2024, "MIN")
# print_game_summary(conn, 2024, "MIN", "2024_01_MIN_NYG")

# print_every_season_summary(conn, "MIN")
#-------------------------------------------------------------#
end <- Sys.time()

# Print execution time
cat("⏱️ Execution Time:", round(difftime(end, start, units = "secs"), 2),
    "seconds\n")

dbDisconnect(conn)
