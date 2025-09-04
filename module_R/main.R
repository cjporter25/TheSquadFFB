library(DBI)
library(RSQLite)
source("module_R/query_utils.R")
# Use "source" when referencing other script files

json_path <- "app_data.json"
conn <- dbConnect(SQLite(), "nfl_pbp.db")
start <- Sys.time()
#-------------------------------------------------------------#
print_season_summary(conn, 2024, "CLE", json_path)
get_historical_matches(conn, 10, "CLE", "CIN")
#-------------------------------------------------------------#
end <- Sys.time()
cat("⏱️ Execution Time:", round(difftime(end, start, units = "secs"), 2),
    "seconds\n")
dbDisconnect(conn)
