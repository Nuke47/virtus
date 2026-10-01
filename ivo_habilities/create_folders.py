import os

base_dir = r"d:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\ivo_habilities\lua"

dirs = [
    os.path.join(base_dir, "autorun"),
    os.path.join(base_dir, "ivo_habilities"),
]

for d in dirs:
    os.makedirs(d, exist_ok=True)
    
print("Folders created.")
