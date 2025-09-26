library(DBI)
library(RSQLite)
source("module_R/query_utils.R")
# Use "source" when referencing other script files

json_path <- "app_data.json"
main_conn <- dbConnect(SQLite(), "nfl_pbp.db")
team_conn <- dbConnect(SQLite(), "nfl_team_pbp.db")
ss_conn <- dbConnect(SQLite(), "nfl_team_ss.db")
start <- Sys.time()
#-------------------------------------------------------------#
print_season_summary(main_conn, 2024, "MIN", json_path)
#-------------------------------------------------------------#
end <- Sys.time()
cat("⏱️ Execution Time:", round(difftime(end, start, units = "secs"), 2),
    "seconds\n")
dbDisconnect(main_conn)
dbDisconnect(team_conn)
dbDisconnect(ss_conn)
