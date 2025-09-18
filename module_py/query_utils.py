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

def get_rb_yardage_bd(passes, comp_passes, incomp_passes, runs):
    # Have to create a deep copy because the incoming data frame
    #   is a visual slice of the original big query, not a copy
    passes = passes.copy()
    comp_passes = comp_passes.copy()
    incomp_passes = incomp_passes.copy()
    runs = runs.copy()

    # Create new column in existing data frame to track attempted
    #   yards regardless of completion
    passes["attempted_yards"] = np.where(
        passes["complete_pass"] == 1,
        passes["yards_gained"],
        passes["air_yards"]
    )
    passes["buckets"] = pd.cut(
        passes["attempted_yards"],
        bins=[-np.inf, 5, 10, 15, 20, np.inf],
        labels=["0-4", "5-9", "10-14", "15-19", "20+"],
        right=False
    )
    comp_passes["buckets"] = pd.cut(
        comp_passes["yards_gained"],
        bins=[-np.inf, 5, 10, 15, 20, np.inf],
        labels=["0-4", "5-9", "10-14", "15-19", "20+"],
        right=False
    )
    incomp_passes["buckets"] = pd.cut(
        incomp_passes["air_yards"],
        bins=[-np.inf, 5, 10, 15, 20, np.inf],
        labels=["0-4", "5-9", "10-14", "15-19", "20+"],
        right=False
    )
    breakdown = {"a_group": convert_group_to_dict(passes["buckets"]),
                 "c_group": convert_group_to_dict(comp_passes["buckets"]),
                 "ic_group": convert_group_to_dict(incomp_passes["buckets"])
                 }
    return breakdown

def convert_group_to_dict(group):
    return group.value_counts().sort_index().to_dict()

def get_rb_season_summary(season, name):
    result = get_player_involved_plays(season, name)
    

    run_plays = result[result["play_type"] == "run"]
    num_r_attempts = len(run_plays)
    total_r_yds = run_plays["yards_gained"].sum()
    avg_ypc = round(run_plays["yards_gained"].mean(), 2)

    pass_plays = result[result["play_type"] == "pass"]
    num_p_attempts = len(pass_plays)

    comp_passes = pass_plays[pass_plays["complete_pass"] == 1]
    num_comp_p = len(comp_passes)
    total_p_yds = comp_passes["yards_gained"].sum()
    # Average yards per "completed" pass
    avg_ypp = round(comp_passes["yards_gained"].mean(), 2)

    incomp_passes = pass_plays[pass_plays["incomplete_pass"] == 1]
    num_incomp_p = len(incomp_passes)
    perc_comp = round((num_comp_p/num_p_attempts) * 100, 1)

    

    yardage_bd = get_rb_yardage_bd(pass_plays, comp_passes, 
                                   incomp_passes, run_plays)


    return {"season": season,
            "name": name, 
            "num_r_attempts": num_r_attempts,
            "total_r_yds": total_r_yds, 
            "avg_ypc": avg_ypc, 
            "num_p_attempts": num_p_attempts,
            "total_p_yds" : total_p_yds,
            "num_comp_p": num_comp_p,
            "num_incomp_p": num_incomp_p, 
            "perc_comp": perc_comp,
            "avg_ypp": avg_ypp,
            "yardage_bd": yardage_bd}

def print_rb_season_summary(p_stats):
    print("Player: " + p_stats["name"] + " (" + str(p_stats["season"]) + ") Summary")
    print("Total Attempted R: " + str(p_stats["num_r_attempts"]))
    print("      Total R Yds: " + str(p_stats["total_r_yds"]))
    # Total Team attempted runs/player attempted runs
    print(" Run Target Share: " + "PLACEHOLDER")
    print("      Average YPC: " + str(p_stats["avg_ypc"]))
    print("Total Attempted P: " + str(p_stats["num_p_attempts"]))
    print("      Total P Yds: " + str(p_stats["total_p_yds"]))
    print("Pass Target Share: " + "PLACEHOLDER")
    print("  Num Comp Passes: " + str(p_stats["num_comp_p"]))
    print("Num Incomp Passes: " + str(p_stats["num_incomp_p"]))
    print(" Perc P Completed: " + str(p_stats["perc_comp"]) + "%")
    print(p_stats["yardage_bd"])




