source("install/setup_utils.R")

# === Establish local folder .db file ===
main_db_path <- "nfl_pbp.db"
team_db_path <- "nfl_team_pbp.db"
json_path <- "app_data.json"

# === Connect to (or create) SQLite database if not there ===
main_db_conn <- dbConnect(SQLite(), main_db_path)
team_db_conn <- dbConnect(SQLite(), team_db_path)

# === Load in and save all plays to local nfl_pbp.db ===
load_and_save_pbp_seasons(main_db_conn)
# === Load in and save all team abbr to app_data.json ===
update_team_list_json(main_db_conn, json_path)
# === Create and save pbp based on specific teams in new db ===
save_team_pbps(main_db_conn, team_db_conn, json_path)

# === Close DB connection ===
dbDisconnect(main_db_conn)
dbDisconnect(team_db_conn)
