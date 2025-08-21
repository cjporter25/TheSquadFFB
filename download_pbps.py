import requests
import os
import pandas as pd
from pathlib import Path

DATA_DIR = Path("data/pbp_parquet")
DATA_DIR.mkdir(parents=True, exist_ok=True)

base_url = "https://github.com/nflverse/nflverse-data/releases/download/play_by_play/pbp_{year}.parquet"

for year in range(2013, 2024):
    url = base_url.format(year=year)
    out_path = DATA_DIR / f"pbp_{year}.parquet"

    print(f"Downloading {year}...")
    try:
        response = requests.get(url, allow_redirects=True)
        response.raise_for_status()

        with open(out_path, "wb") as f:
            f.write(response.content)

        print(f"✓ Saved: {out_path}")
    except Exception as e:
        print(f"✗ Failed: {year} – {e}")


df = pd.read_parquet("data/pbp_parquet/pbp_2023.parquet")
print(df.head())

