import subprocess
import sys

cmd = subprocess.run(["flutter", "analyze", "lib/"], capture_output=True, text=True, shell=True)
with open("analyze5.txt", "w", encoding="utf-8") as f:
    f.write(cmd.stdout)
    f.write(cmd.stderr)
