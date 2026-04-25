import os
import glob
import re

project_dir = r"d:\GodotProject\Marble\MarbleGame"
api_spec_path = r"d:\GodotProject\Marble\docs\API_SPEC.md"

def sync_api():
    print(">>> Syncing API Documentation from GDScript files...")
    
    gd_files = glob.glob(os.path.join(project_dir, "*.gd"))
    api_content = ["# 技術參考手冊 (API_SPEC.md)\n\n", "本文件由 `tools/api_syncer.py` 自動生成，手動修改可能會被覆蓋。\n\n"]
    
    for gd_file in gd_files:
        basename = os.path.basename(gd_file)
        api_content.append(f"## {basename}\n")
        
        with open(gd_file, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Extract variables (var, @onready var)
        vars_found = re.findall(r"(?:@onready\s+)?var\s+(\w+)", content)
        if vars_found:
            api_content.append("### 變數 (Variables)\n")
            for v in vars_found:
                api_content.append(f"- `{v}`\n")
            api_content.append("\n")
            
        # Extract functions
        funcs_found = re.findall(r"func\s+(\w+)\s*\(", content)
        if funcs_found:
            api_content.append("### 函數 (Functions)\n")
            for fn in funcs_found:
                if not fn.startswith("_"): # Skip private/virtual methods usually
                    api_content.append(f"- `{fn}()`\n")
            api_content.append("\n")
            
    with open(api_spec_path, "w", encoding="utf-8") as f:
        f.writelines(api_content)
        
    print(f"[OK] API_SPEC.md successfully updated from {len(gd_files)} source files.")

if __name__ == "__main__":
    sync_api()
