import sys 
import os
import subprocess
import requests
from query_utils import *


# Run R script. This file must be ran from the main 
#   project folder. Using "python module_py/main.py"
subprocess.run(["Rscript", "module_R/main.R"], check=True)

result = get_rb_season_summary(2025, "JAX", "T.Hunter")
print_rb_season_summary(result)

result = get_rb_season_summary(2025, "GB", "R.Doubs")
print_rb_season_summary(result)

result = get_rb_season_summary(2025, "GB", "J.Jacobs")
print_rb_season_summary(result)

result = get_rb_season_summary(2025, "GB", "J.Love")
print_rb_season_summary(result)

result = get_team_season_summary(2025, "GB")
print(result)

# API SANITY CHECK

BASE_URL = "http://127.0.0.1:8000"
name = "Justin Jefferson"
team_abbr = "MIN"

# POST TEST
resp = requests.post(f"{BASE_URL}/players/summary",
                  json={"name":name,"team_abbr":team_abbr})
print("POST /players/summary:", resp.status_code, resp.json())

# GET W/ PARAMS TEST
resp= requests.get(f"{BASE_URL}/players?team_abbr=MIN&name=Justin%20Jefferson")
print("GET /players?[param1]&[param2]", resp.status_code, resp.json())

# GET W/ EXACT ROUTE TEST
resp= requests.get(f"{BASE_URL}/players/MIN/Justin%20Jefferson")
print("GET /players/{team_abbr}/{name}:", resp.status_code, resp.json())