import os
import glob
from datetime import datetime

docs_dir = r"d:\GodotProject\Marble\docs"
project_dir = r"d:\GodotProject\Marble\MarbleGame"

def check_health():
    print("=== Marble Table AI Handover Health Check ===")
    
    # 1. Check Logs
    log_files = glob.glob(os.path.join(docs_dir, "logs", "*.md"))
    log_count = len(log_files)
    print(f"[LOGS] Found {log_count} log files.")
    if log_count >= 10:
        print("⚠️ [ALERT] LOG_OVERFLOW: Log count is high. Please run log compaction before handover.")
    
    # 2. Check API Doc Drift
    api_spec_path = os.path.join(docs_dir, "API_SPEC.md")
    if os.path.exists(api_spec_path):
        api_mtime = os.path.getmtime(api_spec_path)
        
        gd_files = glob.glob(os.path.join(project_dir, "*.gd"))
        newest_gd = max([os.path.getmtime(f) for f in gd_files]) if gd_files else 0
        
        if newest_gd > api_mtime:
            print("(!) [ALERT] API_OUTDATED: Code has changed since last API_SPEC update. Please run 'python tools/api_syncer.py'.")
        else:
            print("[OK] API_SPEC is up to date with code changes.")
    else:
        print("[-] [ERROR] API_SPEC.md missing! Please run 'python tools/api_syncer.py' to generate.")

    # 3. Check Decisions
    decisions = glob.glob(os.path.join(docs_dir, "decisions", "ADR-*.md"))
    print(f"[DECISIONS] Found {len(decisions)} Architectural Decision Records.")
    if not decisions:
        print("⚠️ [ALERT] NO_DECISIONS: No ADRs found. Critical logic might be lost.")

    print("=============================================")

if __name__ == "__main__":
    check_health()
