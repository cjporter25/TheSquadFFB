import sqlite3
import pandas as pd
import numpy as np

CONN = sqlite3.connect("nfl_pbp.db")

# Player Important Info
#   1. Personal Stats (Season)
#       - Total yards running
#           - Avg Yds per carry
#       - Total yards passing
#           - Average passing yards
#           - Completed vs. non-completed

def get_player_involved_plays(season, name):
    table = "pbp_" + str(season)
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
    return result

def get_rb_season_summary(season, name):
    result = get_player_involved_plays(season, name)
    run_plays = result[result["play_type"] == "run"]
    num_r_attempts = len(run_plays)
    avg_ypc = round(run_plays["yards_gained"].mean(), 2)

    pass_plays = result[result["play_type"] == "pass"]
    num_p_attempts = len(pass_plays)
    comp_passes = pass_plays[pass_plays["complete_pass"] == 1]
    num_comp_p = len(comp_passes)
    incomp_passes = pass_plays[pass_plays["incomplete_pass"] == 1]
    num_incomp_p = len(incomp_passes)
    perc_comp = round((num_comp_p/num_p_attempts), 2)
    # Average yards per "completed" pass
    avg_ypp = round(comp_passes["yards_gained"].mean(), 2)
    return {"season": season,
            "name": name, 
            "num_r_attempts": num_r_attempts, 
            "avg_ypc": avg_ypc, 
            "num_p_attempts": num_p_attempts,
            "num_comp_p": num_comp_p,
            "num_incomp_p": num_incomp_p, 
            "perc_comp": perc_comp,
            "avg_ypp": avg_ypp}

def print_rb_season_summary(p_stats):
    print("Player: " + p_stats["name"] + " (" + str(p_stats["season"]) + ") Summary")
    print("Total Attempted R: " + str(p_stats["num_r_attempts"]))
    # Total Team attempted runs/player attempted runs
    print(" Run Target Share: " + "PLACEHOLDER")
    print("      Average YPC: " + str(p_stats["avg_ypc"]))
    print("Total Attempted P: " + str(p_stats["num_p_attempts"]))
    print("  Num Comp Passes: " + str(p_stats["num_comp_p"]))
    print("Num Incomp Passes: " + str(p_stats["num_incomp_p"]))
    print(" Perc P Completed: " + str(p_stats["perc_comp"]))




