source("install/setup_utils.R")

# === Establish local folder .db file ===
db_path <- "nfl_pbp.db"
json_path <- "app_data.json"

# === Connect to (or create) SQLite database if not there ===
conn <- dbConnect(SQLite(), db_path)

# === Load in and save to local db ===
load_and_save_pbp_seasons(conn)
# === Load in and save team abbr to local json ===
update_team_list_json(conn, json_path)

# === Close DB connection ===
dbDisconnect(conn)
