import sys 
import os
import subprocess
from query_utils import *


# Run R script. This file must be ran from the main 
#   project folder. Using "python module_py/main.py"
subprocess.run(["Rscript", "module_R/main.R"], check=True)


result = get_rb_season_summary(2024, "T.Tracy")
# [num_r_attempts, avg_ypc, num_p_attempts, num_comp_p, num_incomp_p, avg_ypp]
print_rb_season_summary(result)

result = get_rb_season_summary(2024, "T.Etienne")
