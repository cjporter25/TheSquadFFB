library(DBI)
library(RSQLite)
source("module_R/query_utils.R")
# Use "source" when referencing other script files

json_path <- "app_data.json"
conn <- dbConnect(SQLite(), "nfl_pbp.db")
start <- Sys.time()
#-------------------------------------------------------------#
print_season_summary(conn, 2024, "NYG", json_path)
#print_season_summary(conn, 2023, "NYG", json_path)
# get_historical_match_stats(conn, 3, "NYG", "WAS")
# print_season_summary(conn, 2025, "MIN", json_path)
#-------------------------------------------------------------#
end <- Sys.time()
cat("⏱️ Execution Time:", round(difftime(end, start, units = "secs"), 2),
    "seconds\n")
dbDisconnect(conn)
