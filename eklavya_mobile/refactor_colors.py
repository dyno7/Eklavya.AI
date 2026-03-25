import os
import re

lib_dir = r"d:\Projects\Eklavya.AI\eklavya_mobile\lib"

pattern = re.compile(r'AppColors\.([a-zA-Z0-9_]+)')

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            if "app_colors.dart" in path or "app_theme.dart" in path or "app_typography.dart" in path:
                continue

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            new_content = pattern.sub(r'context.colors.\1', content)

            if new_content != content:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)
print("Done")
