#!/usr/bin/env bash
# ==============================================================================
# Universal System Auto-Updater (v2.0 Ultimate macOS Launcher)
# Double-click launcher for macOS Finder
# ==============================================================================
cd "$(dirname "$0")" || exit 1
chmod +x ./Update-Mac-Linux.sh

clear
echo "==================================================================="
echo "    UNIVERSAL SYSTEM AUTO-UPDATER & DIAGNOSTICS SUITE (v2.0)       "
echo "==================================================================="
echo " macOS Platform Engine"
echo ""
echo " Please select an operation mode:"
echo ""
echo "   [1] Full System Check, Health Diagnostics & Upgrade (Recommended)"
echo "   [2] Full Upgrade + Automatically Install Missing Essentials (Python, Node, etc.)"
echo "   [3] Unattended / Hands-Free Mode (Runs Everything Silently)"
echo "   [4] Exit"
echo ""
echo "==================================================================="
read -p " Enter choice [1-4] (Default is 1): " MODE

if [ -z "$MODE" ]; then MODE=1; fi
if [ "$MODE" = "4" ]; then exit 0; fi

if [ "$MODE" = "2" ]; then
    ./Update-Mac-Linux.sh --install-essentials
elif [ "$MODE" = "3" ]; then
    ./Update-Mac-Linux.sh --unattended
else
    ./Update-Mac-Linux.sh
fi

echo ""
read -p " Execution complete. Press [Enter] to close this window..."
