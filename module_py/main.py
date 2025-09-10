import sys 
import os
import subprocess
from query_utils import *


# Run R script. This file must be ran from the main 
#   project folder. Using "python module_py/main.py"
subprocess.run(["Rscript", "module_R/main.R"], check=True)


result = get_player_summary(2024, "T.Tracy")
print(result)