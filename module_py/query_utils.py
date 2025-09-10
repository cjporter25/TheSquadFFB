import sqlite3
import pandas as pd

CONN = sqlite3.connect("nfl_pbp.db")

def get_player_summary(season, name):
    table = "pbp_" + str(season)
    print(table)
    query = f"""
        SELECT game_id, posteam, play_type, yards_gained,
        rusher_player_name, rushing_yards, rush_attempt,
        passer_player_name, passing_yards, air_yards,
        receiver_player_name, receiving_yards,
        complete_pass, incomplete_pass
        FROM {table}
        WHERE LOWER(rusher_player_name) LIKE '%' || LOWER(?) || '%'
           OR LOWER(receiver_player_name) LIKE '%' || LOWER(?) || '%'
    """
    result = pd.read_sql_query(query, CONN, params=[name, name])
    runs = result[result["play_type"] == "run"]
    passes = result[result["play_type"] == "pass"]
    return [runs, passes]

