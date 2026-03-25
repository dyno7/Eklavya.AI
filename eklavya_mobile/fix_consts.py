import os
import re

lib_dir = r"d:\Projects\Eklavya.AI\eklavya_mobile\lib"

# Regex matches "const ClassName(" or "const [" or "const {"
# Also handles "const Class.constructor("
pattern = re.compile(r'\bconst\s+([A-Z_a-zA-Z0-9.]+\(|\[|\{)')

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            # Do not strip consts from our theme setups if they are intentionally const, 
            # but since AppColors is no longer const anywhere it's invoked, it's fine.
            # Let's skip app_colors.dart to be safe.
            if "app_colors.dart" in path:
                continue

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            # Multiple passes to catch nested `const` that might be separated differently?
            # A single pass should catch all distinct "const " occurrences.
            new_content = pattern.sub(r'\1', content)
            
            # Also let's catch cases where const is used on variables that shouldn't be, 
            # but we only broke usages. So stripping invocations is enough.

            if new_content != content:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)
print("Const stripping done. Now run 'dart fix --apply'")
