import sqlite3
import pandas as pd
import numpy as np

MAIN_CONN = sqlite3.connect("nfl_pbp.db")
TEAM_CONN = sqlite3.connect("nfl_team_pbp.db")
SS_CONN = sqlite3.connect("nfl_team_ss.db")

# Player Important Info
#   1. Personal Stats (Season)
#       - Total yards running
#           - Avg Yds per carry
#       - Total yards passing
#           - Average passing yards
#           - Completed vs. non-completed

def get_player_involved_plays(season, team_abbr, name):
    table = team_abbr + "_pbp"
    query = f"""
        SELECT game_id, posteam, play_type, yards_gained,
        rusher_player_name, rushing_yards, rush_attempt, qb_scramble,
        passer_player_name, passing_yards, air_yards,
        receiver_player_name, receiving_yards,
        complete_pass, incomplete_pass
        FROM {table}
        WHERE season = ?
            AND (
                LOWER(rusher_player_name) LIKE '%' || LOWER(?) || '%'
                OR LOWER(receiver_player_name) LIKE '%' || LOWER(?) || '%'
                )
    """
    result = pd.read_sql_query(query, TEAM_CONN, params=[season, name, name])
    return result

def get_rb_yardage_bd(runs, passes, comp_passes, incomp_passes):
    # Have to create a deep copy because the incoming data frame
    #   is a visual slice of the original big query, not a copy
    runs = runs.copy()
    passes = passes.copy()
    comp_passes = comp_passes.copy()
    incomp_passes = incomp_passes.copy()
    

    # Create new column in existing data frame to track attempted
    #   yards regardless of completion
    runs["buckets"] = pd.cut(
        runs["yards_gained"],
        bins=[-np.inf, 5, 10, 15, 20, np.inf],
        labels=["0-4", "5-9", "10-14", "15-19", "20+"],
        right=False
    )
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

    breakdown = {"r_group": convert_group_to_dict(runs["buckets"]),
                 "a_group": convert_group_to_dict(passes["buckets"]),
                 "c_group": convert_group_to_dict(comp_passes["buckets"]),
                 "ic_group": convert_group_to_dict(incomp_passes["buckets"]),
                 }
    return breakdown

def get_rb_season_summary(season, team_abbr, name):
    result = get_player_involved_plays(season, team_abbr, name)
    

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

    yardage_bd = get_rb_yardage_bd(run_plays, pass_plays, 
                                   comp_passes, incomp_passes)

    return {"season": season,
            "name": name, 
            "num_r_attempts": num_r_attempts,
            "r_group": yardage_bd["r_group"],
            "total_r_yds": total_r_yds, 
            "avg_ypc": avg_ypc, 
            "num_p_attempts": num_p_attempts,
            "a_group": yardage_bd["a_group"],
            "total_p_yds" : total_p_yds,
            "num_comp_p": num_comp_p,
            "c_group": yardage_bd["c_group"],
            "num_incomp_p": num_incomp_p, 
            "ic_group": yardage_bd["ic_group"],
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
    print(" r_group: ", p_stats["r_group"])
    print(" a_group: ", p_stats["a_group"])
    print(" c_group: ", p_stats["c_group"])
    print("ic_group: ", p_stats["ic_group"])

def convert_group_to_dict(group):
    return group.value_counts().sort_index().to_dict()



