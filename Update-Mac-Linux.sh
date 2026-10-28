#!/usr/bin/env bash
# ==============================================================================
# Universal System Auto-Updater & Diagnostics (v2.0 Ultimate Edition)
# Operating Systems: macOS (Apple Silicon & Intel) & Linux Distributions
# ==============================================================================

# Script Directory & Logging Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/Logs"
mkdir -p "${LOG_DIR}"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${LOG_DIR}/Update-Log-Unix-${TIMESTAMP}.txt"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Parse Arguments
INSTALL_ESSENTIALS=false
SKIP_ESSENTIALS=false
UNATTENDED=false

for arg in "$@"; do
    case "$arg" in
        --install-essentials) INSTALL_ESSENTIALS=true ;;
        --skip-essentials)    SKIP_ESSENTIALS=true ;;
        --unattended|-y)      UNATTENDED=true ;;
    esac
done

log() {
    local level="$1"
    local msg="$2"
    local time_str
    time_str=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$time_str] [$level] $msg" >> "${LOG_FILE}"

    case "$level" in
        "SUCCESS") echo -e "  ${GREEN}[+]${NC} $msg" ;;
        "WARN")    echo -e "  ${YELLOW}[!]${NC} $msg" ;;
        "ERROR")   echo -e "  ${RED}[-]${NC} $msg" ;;
        "STEP")    echo -e "\n${CYAN}>>>${NC} ${WHITE}$msg${NC}" ;;
        "SUBSTEP") echo -e "    ${GRAY}*${NC} $msg" ;;
        *)         echo -e "  $msg" ;;
    esac
}

show_banner() {
    clear
    echo -e "${CYAN}==========================================================================${NC}"
    echo -e "${WHITE}    UNIVERSAL SYSTEM AUTO-UPDATER & DIAGNOSTICS (v2.0 ULTIMATE)          ${NC}"
    echo -e "${CYAN}         Maxed-Out System, Runtime, Ecosystem & Healing Suite            ${NC}"
    echo -e "${CYAN}==========================================================================${NC}"
    echo -e "${GRAY} OS Detected    :${NC} $(uname -s) ($(uname -m))"
    echo -e "${GRAY} Log File       :${NC} ${LOG_FILE}"
    echo -e "${GRAY} Started At     :${NC} $(date)"
    echo -e "${CYAN}==========================================================================${NC}\n"
}

# ------------------------------------------------------------------------------
# 0. ENVIRONMENT HEALING & DIAGNOSTICS
# ------------------------------------------------------------------------------
invoke_environment_healing() {
    log "STEP" "Running System Health Checks & Environment Diagnostics..."

    # Check Disk Space
    local free_space
    free_space=$(df -h / | awk 'NR==2 {print $4}')
    log "SUBSTEP" "Free disk space on root: ${free_space}"

    # macOS Specific Diagnostics
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # Ensure Homebrew path is loaded for Apple Silicon or Intel
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        # Xcode Command Line Tools check
        if ! xcode-select -p >/dev/null 2>&1; then
            log "WARN" "Xcode Command Line Tools are missing. Prompting installation..."
            xcode-select --install 2>/dev/null
        else
            log "SUBSTEP" "Xcode Command Line Tools are installed."
        fi

        # Homebrew health
        if command -v brew >/dev/null 2>&1; then
            log "SUBSTEP" "Homebrew detected. Environment paths validated."
        fi
    fi

    log "SUCCESS" "Environment diagnostics complete."
}

# ------------------------------------------------------------------------------
# 1. SUGGESTED ESSENTIALS & RECOMMENDED APPS (MACOS)
# ------------------------------------------------------------------------------
invoke_suggested_essentials_mac() {
    if [[ "$SKIP_ESSENTIALS" == true ]]; then
        return
    fi

    log "STEP" "Checking for Recommended Developer Essentials & Apps..."

    # Check Homebrew first
    if ! command -v brew >/dev/null 2>&1; then
        echo -e "${YELLOW}  [MISSING] Homebrew (The standard package manager for macOS)${NC}"
        echo -e "${CYAN}  Would you like to install Homebrew now? [Y/n]${NC}"
        read -r install_brew
        if [[ -z "$install_brew" || "$install_brew" =~ ^[Yy]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [[ -x "/opt/homebrew/bin/brew" ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
        fi
    fi

    if ! command -v brew >/dev/null 2>&1; then
        log "WARN" "Homebrew not available. Skipping automatic app installations."
        return
    fi

    # Matrix of essential tools (Name : Command : Brew Cask/Formula : App Bundle Name : Description)
    declare -a ESSENTIALS=(
        "Python 3:python3:python:Python.app:Official Python 3 runtime & pip"
        "Node.js LTS:node:node::JavaScript engine & npm"
        "Git:git:git::Standard version control system"
        "Visual Studio Code:code:visual-studio-code:Visual Studio Code.app:Extensible source code editor (Cask)"
        "Keka Archiver:keka:keka:Keka.app:Powerful high-ratio file archiver (Cask)"
        "Google Chrome:google-chrome:google-chrome:Google Chrome.app:Modern web browser (Cask)"
        "iTerm2:iterm2:iterm2:iTerm.app:Advanced terminal replacement (Cask)"
        "Starship:starship:starship::Fast customizable cross-shell prompt"
        "Docker Desktop:docker:docker:Docker.app:Container application development suite (Cask)"
    )

    declare -a MISSING_NAMES=()
    declare -a MISSING_TARGETS=()

    for item in "${ESSENTIALS[@]}"; do
        IFS=":" read -r name cmd pkg app_name desc <<< "$item"
        local found=false
        if command -v "$cmd" >/dev/null 2>&1; then found=true; fi
        if [[ -n "$app_name" ]]; then
            if [[ -d "/Applications/${app_name}" || -d "${HOME}/Applications/${app_name}" ]]; then found=true; fi
        fi
        if brew list --cask "$pkg" >/dev/null 2>&1 || brew list "$pkg" >/dev/null 2>&1; then found=true; fi

        if [[ "$found" == true ]]; then
            echo -e "    ${GREEN}[INSTALLED]${NC} ${name} (${desc})"
        else
            echo -e "    ${YELLOW}[MISSING]${NC}   ${name} (${desc})"
            MISSING_NAMES+=("$name")
            MISSING_TARGETS+=("$pkg")
        fi
    done

    local count=${#MISSING_NAMES[@]}
    if [[ $count -eq 0 ]]; then
        log "SUCCESS" "All standard recommended apps & essentials are installed!"
        return
    fi

    echo ""
    log "INFO" "Found ${count} recommended application(s) not yet installed on this Mac."

    declare -a TO_INSTALL=()
    if [[ "$INSTALL_ESSENTIALS" == true || "$UNATTENDED" == true ]]; then
        TO_INSTALL=("${MISSING_TARGETS[@]}")
    else
        echo -e "${MAGENTA}==========================================================================${NC}"
        echo -e "${WHITE}                   OPTIONAL RECOMMENDED APPS INSTALLER                    ${NC}"
        echo -e "${MAGENTA}==========================================================================${NC}"
        for i in "${!MISSING_NAMES[@]}"; do
            echo -e "  [${CYAN}$((i+1))${NC}] ${WHITE}${MISSING_NAMES[$i]}${NC}"
        done
        echo -e "  [${GREEN}A${NC}] Install ALL Missing Essentials"
        echo -e "  [${GRAY}S${NC}] Skip & Continue with Updates Only (Default)"
        echo -e "${MAGENTA}--------------------------------------------------------------------------${NC}"
        read -p "  Enter choice ([A], numbers separated by comma e.g. '1, 3', or [S]): " choice

        choice_upper=$(echo "$choice" | tr '[:lower:]' '[:upper:]')
        if [[ -z "$choice" || "$choice_upper" == "S" ]]; then
            log "INFO" "Skipping optional installs. Proceeding to system updates..."
            return
        elif [[ "$choice_upper" == "A" ]]; then
            TO_INSTALL=("${MISSING_TARGETS[@]}")
        else
            IFS=',' read -ra ADDR <<< "$choice"
            for idx in "${ADDR[@]}"; do
                clean_idx=$(echo "$idx" | tr -d ' ')
                if [[ "$clean_idx" =~ ^[0-9]+$ ]]; then
                    target_idx=$((clean_idx - 1))
                    if [[ $target_idx -ge 0 && $target_idx -lt $count ]]; then
                        TO_INSTALL+=("${MISSING_TARGETS[$target_idx]}")
                    fi
                fi
            done
        fi
    fi

    if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
        log "STEP" "Installing ${#TO_INSTALL[@]} selected application(s)..."
        for pkg in "${TO_INSTALL[@]}"; do
            log "SUBSTEP" "Installing ${pkg} via Homebrew..."
            brew install "$pkg" 2>&1 | tee -a "${LOG_FILE}" || brew install --cask "$pkg" 2>&1 | tee -a "${LOG_FILE}"
        done
        log "SUCCESS" "Selected essentials installed!"
    fi
}

# ------------------------------------------------------------------------------
# 2. MACOS SYSTEM & HOMEBREW UPDATES
# ------------------------------------------------------------------------------
update_macos() {
    log "STEP" "Scanning macOS Package Managers & System Software..."

    if command -v brew >/dev/null 2>&1; then
        log "SUBSTEP" "Updating Homebrew index..."
        brew update 2>&1 | tee -a "${LOG_FILE}"
        
        log "SUBSTEP" "Upgrading CLI packages..."
        brew upgrade 2>&1 | tee -a "${LOG_FILE}"

        log "SUBSTEP" "Upgrading Desktop GUI applications (Casks)..."
        brew upgrade --cask --greedy 2>&1 | tee -a "${LOG_FILE}"
        
        log "SUBSTEP" "Cleaning old package cache versions..."
        brew cleanup -s 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "Homebrew packages & Casks up to date!"
    fi

    if command -v mas >/dev/null 2>&1; then
        log "SUBSTEP" "Checking Mac App Store applications (mas)..."
        mas upgrade 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "Mac App Store apps updated."
    fi

    if command -v softwareupdate >/dev/null 2>&1; then
        log "SUBSTEP" "Checking Apple System Software updates..."
        sudo softwareupdate -ia --verbose 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "Apple System Software update check complete."
    fi
}

# ------------------------------------------------------------------------------
# 3. LINUX DISTRIBUTION PACKAGE MANAGERS
# ------------------------------------------------------------------------------
update_linux() {
    log "STEP" "Detecting Linux Package Managers..."

    if command -v apt-get >/dev/null 2>&1; then
        log "SUBSTEP" "Updating APT repositories and upgrading packages..."
        sudo apt-get update -y 2>&1 | tee -a "${LOG_FILE}"
        sudo apt-get upgrade -y 2>&1 | tee -a "${LOG_FILE}"
        sudo apt-get dist-upgrade -y 2>&1 | tee -a "${LOG_FILE}"
        sudo apt-get autoremove -y 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "APT packages successfully updated."
    fi

    if command -v dnf >/dev/null 2>&1; then
        log "SUBSTEP" "Upgrading DNF packages..."
        sudo dnf upgrade --refresh -y 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "DNF packages successfully updated."
    fi

    if command -v pacman >/dev/null 2>&1; then
        log "SUBSTEP" "Synchronizing and updating Pacman packages..."
        sudo pacman -Syu --noconfirm 2>&1 | tee -a "${LOG_FILE}"
        
        if command -v yay >/dev/null 2>&1; then
            log "SUBSTEP" "Updating AUR packages via yay..."
            yay -Syu --noconfirm 2>&1 | tee -a "${LOG_FILE}"
        elif command -v paru >/dev/null 2>&1; then
            log "SUBSTEP" "Updating AUR packages via paru..."
            paru -Syu --noconfirm 2>&1 | tee -a "${LOG_FILE}"
        fi
        log "SUCCESS" "Arch packages & AUR updated."
    fi

    if command -v zypper >/dev/null 2>&1; then
        log "SUBSTEP" "Refreshing and upgrading Zypper packages..."
        sudo zypper refresh 2>&1 | tee -a "${LOG_FILE}"
        sudo zypper dup -y 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "Zypper packages updated."
    fi

    if command -v flatpak >/dev/null 2>&1; then
        log "SUBSTEP" "Updating Flatpak applications..."
        flatpak update -y 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "Flatpak apps updated."
    fi

    if command -v snap >/dev/null 2>&1; then
        log "SUBSTEP" "Refreshing Snap packages..."
        sudo snap refresh 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "Snap packages updated."
    fi
}

# ------------------------------------------------------------------------------
# 4. UNIVERSAL DEVELOPER ECOSYSTEMS (NODE, PYTHON, RUST, GO, DOTNET)
# ------------------------------------------------------------------------------
update_developer_ecosystem() {
    log "STEP" "Scanning Developer Toolchains & Language Ecosystems..."

    # Node / NPM / PNPM / Yarn / Bun
    if command -v npm >/dev/null 2>&1; then
        log "SUBSTEP" "Updating global NPM packages..."
        npm install -g npm@latest 2>&1 | tee -a "${LOG_FILE}"
        npm update -g 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "NPM packages refreshed."
    fi

    if command -v pnpm >/dev/null 2>&1; then
        log "SUBSTEP" "Updating global PNPM packages..."
        pnpm update -g 2>&1 | tee -a "${LOG_FILE}"
    fi

    if command -v yarn >/dev/null 2>&1; then
        log "SUBSTEP" "Updating global Yarn packages..."
        yarn global upgrade 2>&1 | tee -a "${LOG_FILE}"
    fi

    if command -v bun >/dev/null 2>&1; then
        log "SUBSTEP" "Updating Bun runtime..."
        bun upgrade 2>&1 | tee -a "${LOG_FILE}"
    fi

    # Python & Pip
    PYTHON_BIN=""
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_BIN="python"
    fi

    if [ -n "${PYTHON_BIN}" ]; then
        log "SUBSTEP" "Upgrading Python pip..."
        ${PYTHON_BIN} -m pip install --upgrade --user pip 2>/dev/null
        
        log "SUBSTEP" "Scanning for outdated Python packages..."
        OUTDATED_PACKAGES=$(${PYTHON_BIN} -m pip list --outdated --format=json 2>/dev/null | grep -o '"name": "[^"]*' | cut -d'"' -f4)
        if [ -n "${OUTDATED_PACKAGES}" ]; then
            log "SUBSTEP" "Upgrading outdated Python libraries..."
            echo "${OUTDATED_PACKAGES}" | xargs -n1 ${PYTHON_BIN} -m pip install --upgrade --user 2>&1 | tee -a "${LOG_FILE}"
            log "SUCCESS" "Python packages updated."
        else
            log "SUCCESS" "All Python packages are up to date."
        fi
    fi

    if command -v pipx >/dev/null 2>&1; then
        log "SUBSTEP" "Upgrading isolated pipx applications..."
        pipx upgrade-all 2>&1 | tee -a "${LOG_FILE}"
    fi

    # Rust toolchain & Cargo binaries
    if command -v rustup >/dev/null 2>&1; then
        log "SUBSTEP" "Updating Rust toolchains (rustup)..."
        rustup update 2>&1 | tee -a "${LOG_FILE}"
        log "SUCCESS" "Rust toolchain up to date."
    fi

    if command -v cargo-install-update >/dev/null 2>&1; then
        log "SUBSTEP" "Updating installed Cargo binaries..."
        cargo install-update -a 2>&1 | tee -a "${LOG_FILE}"
    fi

    # .NET Global Tools
    if command -v dotnet >/dev/null 2>&1; then
        log "SUBSTEP" "Updating .NET Global Tools..."
        dotnet tool update --global --all 2>/dev/null
    fi

    # GitHub CLI extensions
    if command -v gh >/dev/null 2>&1; then
        log "SUBSTEP" "Upgrading GitHub CLI extensions..."
        gh extension upgrade --all 2>/dev/null
    fi
}

# ------------------------------------------------------------------------------
# MAIN EXECUTION ROUTINE
# ------------------------------------------------------------------------------
show_banner
invoke_environment_healing

OS_TYPE="$(uname -s)"
case "${OS_TYPE}" in
    Darwin*)
        invoke_suggested_essentials_mac
        update_macos
        ;;
    Linux*)
        update_linux
        ;;
    *)
        log "WARN" "Unsupported OS kernel: ${OS_TYPE}. Attempting generic updates..."
        ;;
esac

update_developer_ecosystem

echo -e "\n${GREEN}==========================================================================${NC}"
echo -e "${WHITE}                       ALL UPDATES COMPLETE!                              ${NC}"
echo -e "${GREEN}==========================================================================${NC}"
echo -e "${GRAY} Full log available at:${NC} ${LOG_FILE}\n"
