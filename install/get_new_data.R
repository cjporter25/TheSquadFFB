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

# === Load in and save all plays to local nfl_pbp.db ===
load_and_save_pbp_seasons(main_conn)
# === Load in and save all team abbr to app_data.json ===
update_team_list_json(main_conn, json_path)
# === Create and save pbp based on specific teams in new db ===
save_new_team_pbps(main_conn, team_conn, json_path, "2025")
# === Audit team pbps to remove duplicates and NA values ===
audit_team_pbp_db(team_conn)
# === Calculate and save team summaries for every season ===
save_team_summs_new(main_conn, team_conn, ss_conn, json_path)
# === Audit summary to ensure there's no duplicate rows ===
audit_ss_db(ss_conn)

# === Close DB connection ===
dbDisconnect(main_conn)
dbDisconnect(team_conn)
dbDisconnect(ss_conn)
