import subprocess

# Run R script. This file must be ran from the main 
#   project folder. Using "python module_py/main.py"
subprocess.run(["Rscript", "module_R/main.R"], check=True)