import os
import requests
import pandas as pd
import sqlite3
from pathlib import Path

# === CONFIG ===
SEASONS = [2023]  # Expand as needed
DATA_DIR = Path("data/pbp_parquet")
DB_PATH = "nfl_data.db"

# === STEP 1: Download Parquet File ===
def download_parquet(year):
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    url = f"https://github.com/nflverse/nflverse-data/releases/download/pbp/pbp_{year}.parquet"
    out_path = DATA_DIR / f"pbp_{year}.parquet"
    if out_path.exists():
        print(f"[✓] Already downloaded: pbp_{year}.parquet")
        return out_path

    print(f"Downloading PBP for {year}...")
    r = requests.get(url)
    if r.status_code != 200:
        raise Exception(f"Failed to download {year}: Status {r.status_code}")

    # Check if file is likely a Parquet file
    if r.content[:4] != b'PAR1':
        raise Exception(f"Downloaded file for {year} is not a valid Parquet file.")

    with open(out_path, "wb") as f:
        f.write(r.content)
    return out_path

# === STEP 2: Load Parquet and Save to SQLite ===
def save_to_sqlite(file_path, year, conn):
    print(f"Ingesting {file_path.name} into database...")
    df = pd.read_parquet(file_path)
    df["season"] = year
    df.to_sql("play_by_play", conn, if_exists="append", index=False)

def main():
    conn = sqlite3.connect(DB_PATH)
    for year in SEASONS:
        try:
            file_path = download_parquet(year)
            save_to_sqlite(file_path, year, conn)
        except Exception as e:
            print(f"[X] Error for year {year}: {e}")
    conn.close()
    print(f"\n✅ Done! Data saved in '{DB_PATH}'")

if __name__ == "__main__":
    main()
