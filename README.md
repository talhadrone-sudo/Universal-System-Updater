# 🚀 Universal System Auto-Updater Suite (v2.0 Ultimate Edition)

A **zero-dependency, cross-platform, portable system-wide updater and diagnostics suite** designed to be placed on any **USB Pen Drive**, external drive, or cloud storage (Google Drive, OneDrive, Dropbox) and run with **1 click** on any machine.

---

## 🌟 What's New in v2.0 (Ultimate Edition)

* 🛡️ **Automated Environment Healing & Bugfixes**:
  * Auto-heals PowerShell profile errors (e.g. `Set-PSReadLineOption` syntax errors on legacy PowerShell versions).
  * Enforces modern TLS 1.2 / TLS 1.3 protocol standards for uninterrupted package downloads.
  * Auto-repairs broken or corrupted package manager indexes (`winget source reset`).
  * On macOS: Auto-validates Xcode Command Line Tools, Apple Silicon (`/opt/homebrew/bin`) vs Intel (`/usr/local/bin`) paths.
  * Free disk space & active network health diagnostics.
* 📦 **Smart "Suggested Essentials" & Optional Interactive Installer**:
  * Auto-detects whether key foundational tools are missing on the target machine (Python, Node.js LTS, Git, VS Code, 7-Zip / Keka, Chrome, Terminal, Starship, PowerToys).
  * Provides an optional interactive menu allowing you to install missing tools with a single keystroke or skip directly to upgrades.
* ⚡ **Complete Platform Coverage**:
  * **Windows**: Winget desktop apps, Chocolatey, Scoop, Windows Update, NPM, PNPM, Yarn, Bun, Python/Pip, Rust/Cargo, .NET, PowerShell modules.
  * **macOS**: Homebrew CLI formulae, Desktop GUI applications (Casks), Mac App Store (`mas`), Apple System Software Updates, and developer runtimes.
  * **Linux**: APT, DNF, Pacman, AUR (yay/paru), Zypper, Flatpak, Snap, and developer runtimes.
* 🕒 **Installer Safety Watchdog**:
  * 5-minute per-package timeout prevents frozen or poorly behaved installers from stalling execution.
* 📊 **Persistent Execution Logs**:
  * Complete audit logs saved in `Logs/` for every run.

---

## 💻 Operating System Entry Points

| Operating System | 1-Click Entry Point | Engines Covered |
| :--- | :--- | :--- |
| **Windows 10 / 11 / Server** | **`START_HERE_WINDOWS.bat`** | Self-elevates to Admin, runs `Update-Windows.ps1`, diagnoses & upgrades |
| **macOS (Apple Silicon & Intel)** | **`START_HERE_MAC.command`** | Opens Terminal, verifies Homebrew/Xcode, upgrades apps & Apple patches |
| **Linux (Ubuntu, Debian, Fedora, Arch, etc.)** | **`Update-Mac-Linux.sh`** | APT, DNF, Pacman, AUR, Zypper, Flatpak, Snap, Dev Toolchains |
| **Cross-Platform Python Core** | **`universal_updater.py`** | Multi-platform CLI runner with `--install-essentials` and `--unattended` |

---

## ⚡ Quick Start: How to Use from a USB Pen Drive

### 🪟 On Windows:
1. Plug your USB Pen Drive into the PC.
2. Open the `Universal-System-Updater` folder.
3. **Double-click `START_HERE_WINDOWS.bat`**.
4. Choose your preferred mode:
   * `[1]` Full System Check, Health Healing & Upgrade Everything (Recommended)
   * `[2]` Full Upgrade + Automatically Install Missing Essentials (Python, Node, Git, etc.)
   * `[3]` System Diagnostics & Bugfixes Only
   * `[4]` Unattended / Hands-Free Mode

### 🍎 On macOS:
1. Plug your USB Pen Drive into the Mac (or download from Google Drive / OneDrive).
2. Open the `Universal-System-Updater` folder in Finder.
3. **Double-click `START_HERE_MAC.command`**.  
   *(Tip: If macOS displays a Gatekeeper warning because the file was downloaded from the web, right-click `START_HERE_MAC.command` and click **Open**, or run `chmod +x *.command *.sh` in Terminal).*
4. Terminal opens and guides you through Homebrew, GUI Casks, Mac App Store apps, and Apple updates.

### 🐧 On Linux:
1. Open a terminal in the folder:
   ```bash
   chmod +x Update-Mac-Linux.sh
   ./Update-Mac-Linux.sh
   ```

---

## 🔍 Detailed Coverage Matrix

| Category | Windows Engine | macOS & Linux Engine |
| :--- | :--- | :--- |
| **System Diagnostics** | TLS 1.2/1.3 enforcement, Disk space check, PowerShell profile repair, Winget source reset | Xcode CLI check, Apple Silicon path resolution, Homebrew environment diagnosis, Disk space check |
| **Suggested Essentials** | Interactive installer for Python, Node LTS, Git, VS Code, 7-Zip, Chrome, Terminal, Starship, PowerToys | Interactive installer for Homebrew, Python, Node LTS, Git, VS Code, Keka, Chrome, iTerm2, Starship |
| **Desktop Applications** | **Winget** (with 5-minute freeze watchdog, catalog refresh, user pin protection, silent-failure retry) | **Homebrew Casks** (`brew upgrade --cask --greedy`), **Mac App Store CLI** (`mas upgrade`) |
| **Secondary Managers** | **Chocolatey** (`choco upgrade all -y`) & **Scoop** (`scoop update *`) | **Flatpak** (`flatpak update -y`) & **Snap** (`snap refresh`) |
| **OS & Security Patches**| Scans & reports pending **Windows Update** hotfixes and patches | Installs **Apple Software Updates** (`softwareupdate -ia --verbose`), **APT/DNF/Pacman** dist-upgrades |
| **Node.js Ecosystem** | `npm` (self-update + global packages), `pnpm`, `yarn`, `bun` | `npm` (self-update + global packages), `pnpm`, `yarn`, `bun` |
| **Python Ecosystem** | Self-upgrades `pip`, batch upgrades outdated libraries, updates `pipx` | Self-upgrades `pip3`, batch upgrades outdated libraries, updates `pipx` |
| **Compiled Languages** | **Rust** (`rustup` + `cargo-update`), **.NET** global tools (`dotnet tool update`) | **Rust** (`rustup` + `cargo-update`), **.NET** global tools, **Ruby** (`gem update`) |
| **Developer Tools** | **GitHub CLI** (`gh extension upgrade --all`), **PowerShell Modules** (`Update-Module`) | **GitHub CLI** extensions, **Ruby Gems** |
| **Maintenance** | Cleans installer caches (`%TEMP%\WinGet`), purges `pip` wheel caches, verifies `npm` cache | Cleans old package downloads (`brew cleanup -s`), trims wheel cache |
| **Audit Logs** | Timestamped logs in `Logs/Update-Log-Windows-YYYY-MM-DD.txt` | Timestamped logs in `Logs/Update-Log-Unix-YYYY-MM-DD.txt` |

---

## 📁 Package Contents

```text
Universal-System-Updater/
├── START_HERE_WINDOWS.bat       <-- 1-Click Windows Launcher (Auto-Elevates)
├── Update-Windows.ps1           <-- Core Windows PowerShell v2.0 Engine
├── START_HERE_MAC.command       <-- 1-Click macOS Finder Launcher
├── Update-Mac-Linux.sh          <-- Core Unix/macOS/Linux POSIX Engine
├── universal_updater.py         <-- Cross-platform Python Runner
├── README.md                    <-- Complete Suite Documentation
└── Logs/                        <-- Persistent audit logs for every run
```
