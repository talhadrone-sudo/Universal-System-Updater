@echo off
setlocal EnableDelayedExpansion
title Universal System Auto-Updater (v2.0 Ultimate Edition)

:: ----------------------------------------------------------------------
:: Check Administrator Privileges & Self-Elevate
:: ----------------------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ===================================================================
    echo    Requesting Administrator privileges to run system-wide updates...
    echo ===================================================================
    
    :: Attempt to launch elevated process
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$proc = Start-Process cmd -ArgumentList '/c \"\"%~f0\"\" %*' -Verb RunAs -PassThru -ErrorAction SilentlyContinue; if ($proc) { exit 0 } else { exit 1 }"
    if !errorlevel! equ 0 exit /b
    
    echo.
    echo  [!] Note: Administrator elevation was not granted or was cancelled.
    echo  [!] The updater can continue in Standard User mode
    echo      (Updates User Applications, Python, Node, Git, and Diagnostics).
    echo.
    set /p CONTINUE_STD="Do you want to continue in Standard User mode? [Y/n]: "
    if /i "!CONTINUE_STD!"=="n" exit /b
)

:: Ensure working directory is the script folder (Crucial for USB / Network drives)
cd /d "%~dp0"

color 0B
cls
echo ===================================================================
echo     UNIVERSAL SYSTEM AUTO-UPDATER & DIAGNOSTICS SUITE (v2.0)
echo ===================================================================
echo  Working Folder: "%~dp0"
echo.
echo  Please select an operation mode:
echo.
echo    [1] Full System Check, Health Healing & Upgrade Everything (Recommended)
echo    [2] Full Upgrade + Automatically Install Missing Essentials (Python, Node, Git, etc.)
echo    [3] System Diagnostics, Bugfixes & Environment Repair Only
echo    [4] Unattended / Hands-Free Mode (Runs Everything Silently)
echo    [5] Exit
echo.
echo ===================================================================
set /p MODE="Enter choice [1-5] (Default is 1): "

if "%MODE%"=="" set MODE=1
if "%MODE%"=="5" exit /b

if "%MODE%"=="2" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-Windows.ps1" -InstallEssentials
    goto finish
)

if "%MODE%"=="3" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-Windows.ps1" -SkipEssentials -SkipWindowsUpdate
    goto finish
)

if "%MODE%"=="4" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-Windows.ps1" -Unattended
    goto finish
)

:: Default: Mode 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-Windows.ps1"

:finish
echo.
echo ===================================================================
echo  Execution finished. Press any key to close this window.
echo ===================================================================
pause >nul
