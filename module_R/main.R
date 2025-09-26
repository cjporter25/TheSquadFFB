library(DBI)
library(RSQLite)
source("module_R/query_utils.R")
source("install/setup_utils.R")
source("install/audit_db.R")
# Use "source" when referencing other script files

json_path <- "app_data.json"
main_conn <- dbConnect(SQLite(), "nfl_pbp.db")
team_conn <- dbConnect(SQLite(), "nfl_team_pbp.db")
ss_conn <- dbConnect(SQLite(), "nfl_team_ss.db")
start <- Sys.time()
#-------------------------------------------------------------#
print_season_summary(main_conn, 2024, "MIN", json_path)
print_season_summary(main_conn, 2024, "GB", json_path)
print_season_summary(main_conn, 2025, "GB", json_path)
# RUN WHEN UPDATING 2025 STATS
# save_team_summs_new(main_conn, team_conn, ss_conn, json_path)
# audit_nfl_pbp_db(main_conn)
#-------------------------------------------------------------#
end <- Sys.time()
cat("⏱️ Execution Time:", round(difftime(end, start, units = "secs"), 2),
    "seconds\n")
dbDisconnect(main_conn)
dbDisconnect(team_conn)
dbDisconnect(ss_conn)
