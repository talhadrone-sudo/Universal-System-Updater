#!/usr/bin/env python3
"""
Universal System Auto-Updater & Diagnostics Suite (v2.0 Ultimate Edition)
Cross-platform engine for Windows, macOS, and Linux.
"""

import os
import sys
import platform
import subprocess
import argparse
from datetime import datetime

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_DIR = os.path.join(CURRENT_DIR, "Logs")
os.makedirs(LOG_DIR, exist_ok=True)

TIMESTAMP = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
LOG_FILE = os.path.join(LOG_DIR, f"Update-Log-Python-{TIMESTAMP}.txt")

def log(msg, level="INFO"):
    time_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{time_str}] [{level}] {msg}"
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")
    print(formatted)

def parse_args():
    parser = argparse.ArgumentParser(
        description="Universal System Auto-Updater & Diagnostics Suite (v2.0 Ultimate)"
    )
    parser.add_argument(
        "--install-essentials",
        action="store_true",
        help="Automatically install missing essential runtimes (Python, Node, Git, etc.)",
    )
    parser.add_argument(
        "--skip-essentials",
        action="store_true",
        help="Skip checking or installing recommended essentials",
    )
    parser.add_argument(
        "--unattended", "-y",
        action="store_true",
        help="Run without interactive confirmation prompts",
    )
    parser.add_argument(
        "--diagnostics-only",
        action="store_true",
        help="Run system health checks and environment healing only",
    )
    return parser.parse_args()

def main():
    args = parse_args()
    system = platform.system()
    
    print("=" * 72)
    print("       UNIVERSAL SYSTEM AUTO-UPDATER & DIAGNOSTICS (v2.0 ULTIMATE)       ")
    print(f" Platform : {system} ({platform.machine()})")
    print(f" Log File : {LOG_FILE}")
    print("=" * 72)

    if system == "Windows":
        ps1_script = os.path.join(CURRENT_DIR, "Update-Windows.ps1")
        if not os.path.exists(ps1_script):
            log(f"Could not locate {ps1_script}", "ERROR")
            sys.exit(1)

        extra_args = []
        if args.install_essentials:
            extra_args.append("-InstallEssentials")
        if args.skip_essentials:
            extra_args.append("-SkipEssentials")
        if args.unattended:
            extra_args.append("-Unattended")
        if args.diagnostics_only:
            extra_args.extend(["-SkipEssentials", "-SkipWindowsUpdate"])

        cmd = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps1_script] + extra_args
        log("Executing native Windows PowerShell engine...", "INFO")
        subprocess.run(cmd)

    elif system in ("Darwin", "Linux"):
        sh_script = os.path.join(CURRENT_DIR, "Update-Mac-Linux.sh")
        if not os.path.exists(sh_script):
            log(f"Could not locate {sh_script}", "ERROR")
            sys.exit(1)

        os.chmod(sh_script, 0o755)
        extra_args = []
        if args.install_essentials:
            extra_args.append("--install-essentials")
        if args.skip_essentials:
            extra_args.append("--skip-essentials")
        if args.unattended:
            extra_args.append("--unattended")

        log("Executing native Unix Bash engine...", "INFO")
        subprocess.run([sh_script] + extra_args)

    else:
        log(f"Unsupported operating system: {system}", "ERROR")
        sys.exit(1)

    print("\n" + "=" * 72)
    print(" Execution finished.")
    print("=" * 72)

if __name__ == "__main__":
    main()
