library(DBI)
library(RSQLite)

conn <- dbConnect(SQLite(), "nfl_pbp.db")

vikings_2024 <- dbGetQuery(conn, "
  SELECT
    game_id,
    play_type,
    yards_gained,
    passer_player_name,
    passing_yards,
    receiver_player_name,
    receiving_yards
  FROM pbp_2024
  WHERE posteam = 'MIN'
  ORDER BY game_id
")

dbGetQuery(conn, "
  SELECT COUNT(*) FROM pbp_2024 WHERE posteam = 'MIN' AND play_type = 'pass'
")

nrow(vikings_2024)


dbDisconnect(conn)

# Preview the result (only 6 rows)
# head(vikings_2024)

# Print first 20
print(vikings_2024[1:20, ])
# Print first 20 but limit the view to specific rows
# print(vikings_2024[1:20, c("play_type", "player_name", "yards_gained")])
# Print the first 20 but don't print row numbers
# print(vikings_2024[1:20, ], row.names = FALSE)


