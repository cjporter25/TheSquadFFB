source("install/setup_utils.R")
source("install/audit_db.R")

# === Establish local folder .db file ===
main_db_path <- "nfl_pbp.db"
team_db_path <- "nfl_team_pbp.db"
ss_db_path <- "nfl_team_ss.db"

json_path <- "app_data.json"

# === Connect to (or create) SQLite database if not there ===
main_conn <- dbConnect(SQLite(), main_db_path)
team_conn <- dbConnect(SQLite(), team_db_path)
ss_conn <- dbConnect(SQLite(), ss_db_path)


# === Calculate and save team summaries for every season ===
save_new_team_summs(main_conn, team_conn, ss_conn, json_path)


# === Close DB connection ===
dbDisconnect(main_conn)
dbDisconnect(team_conn)
dbDisconnect(ss_conn)
