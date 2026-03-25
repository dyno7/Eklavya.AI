import subprocess
import os

android_dir = r"d:\Projects\Eklavya.AI\eklavya_mobile\android"
cmd = subprocess.run(["powershell", "-c", ".\\gradlew assembleDebug --info --stacktrace"], cwd=android_dir, capture_output=True, text=True)

with open(os.path.join(android_dir, "build_error.txt"), "w", encoding="utf-8") as f:
    f.write(cmd.stdout)
    f.write(cmd.stderr)
