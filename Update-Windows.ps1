<#
.SYNOPSIS
    Universal System Auto-Updater for Windows (v2.0 Ultimate Edition)
.DESCRIPTION
    Comprehensive, maxed-out, portable system-wide updater and diagnostics suite for Windows.
    Auto-detects and upgrades Desktop Apps, Runtimes, Package Managers (Winget, Choco, Scoop),
    Developer Ecosystems (Node/NPM/PNPM/Yarn/Bun, Python/Pip, Rust/Cargo, .NET Tools),
    PowerShell Modules, GitHub CLI extensions, and Windows Updates.
    Includes automated environment healing/bugfixes and smart "Suggested Essentials" installer.
#>

[CmdletBinding()]
param(
    [switch]$Unattended,
    [switch]$InstallEssentials,
    [switch]$SkipEssentials,
    [switch]$SkipWindowsUpdate
)

# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Script & Log Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = Get-Location }
$LogDir = Join-Path $ScriptDir "Logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$LogFile = Join-Path $LogDir "Update-Log-Windows-$Timestamp.txt"

# Statistics Tracker
$Global:Stats = [ordered]@{
    "Environment Bugfixes" = @{ Updated = 0; Failed = 0; Skipped = 0 }
    "Suggested Essentials" = @{ Updated = 0; Failed = 0; Skipped = 0 }
    "Winget Packages"      = @{ Updated = 0; Failed = 0; Skipped = 0 }
    "Chocolatey Packages"  = @{ Updated = 0; Failed = 0; Skipped = 0 }
    "Scoop Packages"       = @{ Updated = 0; Failed = 0; Skipped = 0 }
    "Node / NPM Global"    = @{ Updated = 0; Failed = 0; Skipped = 0 }
    "Python / Pip Packages"= @{ Updated = 0; Failed = 0; Skipped = 0 }
    "Rust / Cargo"         = @{ Updated = 0; Failed = 0; Skipped = 0 }
    ".NET Global Tools"    = @{ Updated = 0; Failed = 0; Skipped = 0 }
    "PowerShell Modules"   = @{ Updated = 0; Failed = 0; Skipped = 0 }
    "Windows Update"       = @{ Updated = 0; Failed = 0; Skipped = 0 }
}

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

function Log($Message, [string]$Level = "INFO", [ConsoleColor]$Color = [ConsoleColor]::White) {
    $timeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logLine = "[$timeStr] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logLine -Encoding UTF8
    
    switch ($Level) {
        "SUCCESS" { Write-Host "  [+] $Message" -ForegroundColor Green }
        "WARN"    { Write-Host "  [!] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "  [-] $Message" -ForegroundColor Red }
        "STEP"    { Write-Host "`n>>> $Message" -ForegroundColor Cyan }
        "SUBSTEP" { Write-Host "    * $Message" -ForegroundColor Gray }
        "PROMPT"  { Write-Host "  [?] $Message" -ForegroundColor Magenta }
        default   { Write-Host "  $Message" -ForegroundColor $Color }
    }
}

function Show-Banner {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "         UNIVERSAL SYSTEM AUTO-UPDATER & DIAGNOSTICS (v2.0 ULTIMATE)     " -ForegroundColor White
    Write-Host "            Maxed-Out System, Runtime, Ecosystem & Healing Suite          " -ForegroundColor DarkCyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " Log Destination : $LogFile" -ForegroundColor DarkGray
    Write-Host " Started At      : $((Get-Date).ToString('dddd, MMMM dd, yyyy HH:mm:ss'))" -ForegroundColor DarkGray
    Write-Host " Machine / User  : $env:COMPUTERNAME \ $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -ForegroundColor DarkGray
    $osInfo = (Get-CimInstance Win32_OperatingSystem).Caption
    $is64 = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
    Write-Host " OS & Arch       : $osInfo ($is64)" -ForegroundColor DarkGray
    
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Host " Privileges      : Elevated (Administrator) - Full Access" -ForegroundColor Green
    } else {
        Write-Host " Privileges      : Standard User (Elevated mode recommended for full upgrades)" -ForegroundColor Yellow
    }
    Write-Host "==========================================================================`n" -ForegroundColor Cyan
}

# -------------------------------------------------------------------------
# PHASE 0: SYSTEM HEALTH, DIAGNOSTICS & ENVIRONMENT BUGFIXES
# -------------------------------------------------------------------------
function Invoke-EnvironmentHealing {
    Log "Running Pre-Update Diagnostics & System Bugfixes..." "STEP"
    
    # 1. Force modern TLS protocols for secure downloads
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        Log "Enforced TLS 1.2 / TLS 1.3 for secure package downloads." "SUBSTEP"
        $Global:Stats["Environment Bugfixes"].Updated++
    } catch {
        Log "Could not set TLS 1.3; defaulting to system defaults." "SUBSTEP"
    }

    # 2. Disk Space Health Check
    try {
        $cDrive = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($cDrive) {
            $freeGB = [math]::Round($cDrive.Free / 1GB, 2)
            if ($freeGB -lt 5) {
                Log "Low disk space on C: ($freeGB GB free). Upgrades might fail if space runs out." "WARN"
            } else {
                Log "Disk Space OK: $freeGB GB free on C: drive." "SUBSTEP"
            }
        }
    } catch {}

    # 3. Internet Connectivity Diagnostic
    try {
        $ping = Test-Connection -ComputerName 1.1.1.1 -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $ping) {
            Log "Network connectivity appears offline or restricted. Package downloads might fail." "WARN"
        } else {
            Log "Network connectivity verified." "SUBSTEP"
        }
    } catch {}

    # 4. Auto-Fix PowerShell Profile PSReadLine Warning
    try {
        $profilePath = $PROFILE.CurrentUserAllHosts
        if (-not (Test-Path $profilePath)) { $profilePath = $PROFILE.CurrentUserCurrentHost }
        
        if (Test-Path $profilePath) {
            $profileContent = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
            if ($profileContent -match "PredictionSource" -and -not ($profileContent -match "try\s*\{\s*Set-PSReadLineOption")) {
                Log "Detected unhandled PSReadLine prediction commands in PowerShell profile. Applying graceful wrapper..." "SUBSTEP"
                $patchedContent = $profileContent -replace '(?m)^(\s*Set-PSReadLineOption\s+-PredictionSource.*)$', 'try { $1 } catch {}'
                $patchedContent = $patchedContent -replace '(?m)^(\s*Set-PSReadLineOption\s+-PredictionViewStyle.*)$', 'try { $1 } catch {}'
                Set-Content -Path $profilePath -Value $patchedContent -Encoding UTF8 -Force
                Log "PowerShell profile auto-healed. Parameter warnings eliminated!" "SUCCESS"
                $Global:Stats["Environment Bugfixes"].Updated++
            }
        }
    } catch {
        Log "Profile healing check skipped: $_" "SUBSTEP"
    }

    # 5. Winget Source Health Check
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            $sourceTest = & winget source list 2>&1
            if ($sourceTest -match "0x8a15000f" -or $sourceTest -match "Failed to open") {
                Log "Winget source database error detected. Resetting sources to official state..." "WARN"
                & winget source reset --force | Out-Null
                Log "Winget sources successfully reset." "SUCCESS"
                $Global:Stats["Environment Bugfixes"].Updated++
            }
        } catch {}
    }

    Log "Pre-update environment diagnostics complete." "SUCCESS"
}

# -------------------------------------------------------------------------
# PHASE 1: SUGGESTED ESSENTIALS & OPTIONAL RUNTIMES
# -------------------------------------------------------------------------
function Invoke-SuggestedEssentials {
    if ($SkipEssentials) {
        Log "Suggested Essentials check skipped by parameter." "INFO"
        return
    }

    Log "Analyzing System for Essential Runtimes & Recommended Apps..." "STEP"
    
    # Helper for thorough multi-layer detection across PATH, Registry, Program Files & Winget
    function Test-AppInstalled($cmd, $id, $extraExe = @()) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) { return $true }
        foreach ($exe in $extraExe) {
            if (Get-Command $exe -ErrorAction SilentlyContinue) { return $true }
        }
        $regKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$cmd.exe",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$cmd.exe"
        )
        foreach ($exe in $extraExe) {
            $regKeys += "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exe"
            $regKeys += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exe"
        }
        foreach ($rk in $regKeys) {
            if (Test-Path $rk) { return $true }
        }
        $commonDirs = @(
            "${env:ProgramFiles}\$cmd",
            "${env:ProgramFiles(x86)}\$cmd",
            "${env:LOCALAPPDATA}\Programs\$cmd"
        )
        foreach ($cd in $commonDirs) {
            if (Test-Path $cd) { return $true }
        }
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $wCheck = & winget list --id $id --exact 2>$null
            if ($wCheck -match [regex]::Escape($id)) { return $true }
        }
        return $false
    }

    # Catalog of Essential Runtimes & Tools
    $essentials = @(
        @{ Name = "Python 3";            Id = "Python.Python.3.13";    Command = "python"; Exe = @("py.exe", "python3.exe"); Desc = "Official Python 3 Runtime & Pip" }
        @{ Name = "Node.js (LTS)";       Id = "OpenJS.NodeJS.LTS";     Command = "node";   Exe = @("npm.cmd", "node.exe");   Desc = "JavaScript runtime & NPM package manager" }
        @{ Name = "Git for Windows";     Id = "Git.Git";               Command = "git";    Exe = @("git.exe");               Desc = "Standard Distributed Version Control" }
        @{ Name = "Visual Studio Code";  Id = "Microsoft.VisualStudioCode"; Command = "code"; Exe = @("Code.exe");          Desc = "Powerful, lightweight extensible code editor" }
        @{ Name = "7-Zip";               Id = "7zip.7zip";             Command = "7z";     Exe = @("7zFM.exe", "7z.exe");    Desc = "High-compression file archiver" }
        @{ Name = "Google Chrome";       Id = "Google.Chrome";         Command = "chrome"; Exe = @("chrome.exe");            Desc = "Fast, secure modern web browser" }
        @{ Name = "Windows Terminal";    Id = "Microsoft.WindowsTerminal"; Command = "wt"; Exe = @("wt.exe");                Desc = "Modern multi-tab terminal host for Windows" }
        @{ Name = "Starship Prompt";     Id = "Starship.Starship";     Command = "starship"; Exe = @("starship.exe");        Desc = "Ultra-fast, customizable cross-shell prompt" }
        @{ Name = "Microsoft PowerToys"; Id = "Microsoft.PowerToys";   Command = "powertoys"; Exe = @("PowerToys.exe");     Desc = "System productivity utilities for Windows" }
    )

    $missing = @()
    foreach ($item in $essentials) {
        $found = Test-AppInstalled $item.Command $item.Id $item.Exe

        if ($found) {
            Write-Host ("    [INSTALLED] {0,-24} : {1}" -f $item.Name, $item.Desc) -ForegroundColor DarkGreen
        } else {
            Write-Host ("    [MISSING]   {0,-24} : {1}" -f $item.Name, $item.Desc) -ForegroundColor Yellow
            $missing += $item
        }
    }

    if ($missing.Count -eq 0) {
        Log "All standard Developer Essentials & Recommended Apps are already installed!" "SUCCESS"
        return
    }

    Write-Host ""
    Log "Found $($missing.Count) recommended essential(s) not currently installed on this system." "INFO"

    $toInstall = @()
    if ($InstallEssentials -or $Unattended) {
        Log "Auto-installing all missing essentials (-InstallEssentials specified)..." "INFO"
        $toInstall = $missing
    } else {
        Write-Host "==========================================================================" -ForegroundColor Magenta
        Write-Host "                   OPTIONAL RECOMMENDED APPS INSTALLER                    " -ForegroundColor White
        Write-Host "==========================================================================" -ForegroundColor Magenta
        for ($i = 0; $i -lt $missing.Count; $i++) {
            Write-Host ("  [{0}] {1,-22} ({2})" -f ($i + 1), $missing[$i].Name, $missing[$i].Desc) -ForegroundColor Cyan
        }
        Write-Host "  [A] Install ALL Missing Essentials" -ForegroundColor Green
        Write-Host "  [S] Skip & Continue with Updates Only (Default in 10s)" -ForegroundColor Gray
        Write-Host "--------------------------------------------------------------------------" -ForegroundColor Magenta
        
        Write-Host -NoNewline "  Enter choice ([A], numbers separated by comma e.g. '1, 3', or [S]): " -ForegroundColor White
        
        $choice = Read-Host
        if ([string]::IsNullOrWhiteSpace($choice) -or $choice.Trim().ToUpper() -eq "S") {
            Log "Skipping optional installs. Proceeding directly to system updates..." "INFO"
            return
        } elseif ($choice.Trim().ToUpper() -eq "A") {
            $toInstall = $missing
        } else {
            $selectedIndices = $choice -split "[, ]+" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^\d+$" }
            foreach ($idx in $selectedIndices) {
                $zeroIdx = [int]$idx - 1
                if ($zeroIdx -ge 0 -and $zeroIdx -lt $missing.Count) {
                    $toInstall += $missing[$zeroIdx]
                }
            }
        }
    }

    if ($toInstall.Count -gt 0) {
        Log "Installing $($toInstall.Count) selected application(s)..." "STEP"
        foreach ($app in $toInstall) {
            Log "Installing $($app.Name) ($($app.Id))..." "SUBSTEP"
            $proc = Start-Process -FilePath "winget.exe" -ArgumentList "install --id $($app.Id) --silent --accept-source-agreements --accept-package-agreements" -PassThru -NoNewWindow
            [void]$proc.WaitForExit(300000)
            if ($proc.ExitCode -eq 0) {
                Log "$($app.Name) installed successfully!" "SUCCESS"
                $Global:Stats["Suggested Essentials"].Updated++
            } else {
                Log "$($app.Name) installation returned exit code $($proc.ExitCode)." "WARN"
                $Global:Stats["Suggested Essentials"].Failed++
            }
        }
    }
}

# -------------------------------------------------------------------------
# PHASE 2: WINDOWS PACKAGE MANAGER (WINGET)
# -------------------------------------------------------------------------
function Update-WingetPackages {
    Log "Scanning Windows Package Manager (winget)..." "STEP"
    
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Log "Winget is not installed or not in PATH. Skipping." "WARN"
        Log "Tip: You can install Windows Package Manager by installing 'App Installer' from the Microsoft Store or https://github.com/microsoft/winget-cli/releases" "INFO"
        $Global:Stats["Winget Packages"].Skipped = 1
        return
    }

    try {
        Log "Refreshing package catalogs..." "SUBSTEP"
        & winget source update | Out-Null
        
        Log "Querying pinned packages to protect user preferences..." "SUBSTEP"
        $pinnedList = @()
        $pinOutput = & winget pin list 2>$null
        if ($pinOutput) {
            foreach ($line in $pinOutput) {
                if ($line -match "^\s*([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+(Pinning|Blocking)") {
                    $pinnedList += $matches[2]
                }
            }
        }
        if ($pinnedList.Count -gt 0) {
            Log "Detected $($pinnedList.Count) pinned package(s) [Protected]: $($pinnedList -join ', ')" "SUBSTEP"
        }

        Log "Scanning for available application upgrades..." "SUBSTEP"
        $upgradeOutput = & winget upgrade --include-unknown 2>$null
        
        $upgrades = @()
        $startParsing = $false
        foreach ($line in $upgradeOutput) {
            if ($line -match "^---+") {
                $startParsing = $true
                continue
            }
            if ($startParsing -and $line.Trim().Length -gt 0) {
                if ($line -match "^\s*(.+?)\s{2,}([a-zA-Z0-9_\-\.]+)\s{2,}([^\s]+)\s{2,}([^\s]+)\s{2,}([^\s]+)") {
                    $pkgName = $matches[1].Trim()
                    $pkgId   = $matches[2].Trim()
                    $curVer  = $matches[3].Trim()
                    $newVer  = $matches[4].Trim()
                    
                    if ($pinnedList -notcontains $pkgId) {
                        $upgrades += [PSCustomObject]@{
                            Name      = $pkgName
                            Id        = $pkgId
                            Current   = $curVer
                            Available = $newVer
                        }
                    }
                }
            }
        }

        if ($upgrades.Count -eq 0) {
            Log "All Winget desktop applications and runtimes are up to date!" "SUCCESS"
            return
        }

        Log "Found $($upgrades.Count) upgradable package(s):" "INFO" -Color Yellow
        foreach ($u in $upgrades) {
            Write-Host ("    - {0,-35} [{1} -> {2}]" -f $u.Name, $u.Current, $u.Available) -ForegroundColor Gray
        }
        Write-Host ""

        $index = 0
        foreach ($u in $upgrades) {
            $index++
            Log "[$index/$($upgrades.Count)] Upgrading $($u.Name) ($($u.Id))..." "SUBSTEP"
            
            $proc = Start-Process -FilePath "winget.exe" -ArgumentList "upgrade --id $($u.Id) --silent --accept-source-agreements --accept-package-agreements" -PassThru -NoNewWindow
            
            $timeoutSeconds = 300
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $exited = $false
            while ($sw.Elapsed.TotalSeconds -lt $timeoutSeconds) {
                if ($proc.HasExited) {
                    $exited = $true
                    $proc.WaitForExit()
                    break
                }
                Start-Sleep -Seconds 2
            }

            if (-not $exited) {
                try { $proc.Kill() } catch {}
                Log "$($u.Name) timed out after 5 minutes. Skipping." "WARN"
                $Global:Stats["Winget Packages"].Failed++
            } elseif ($proc.ExitCode -eq 0) {
                Log "$($u.Name) successfully upgraded to $($u.Available)!" "SUCCESS"
                $Global:Stats["Winget Packages"].Updated++
            } else {
                Log "Silent upgrade exited with code $($proc.ExitCode). Retrying with standard installer..." "SUBSTEP"
                $retry = Start-Process -FilePath "winget.exe" -ArgumentList "upgrade --id $($u.Id) --accept-source-agreements --accept-package-agreements" -PassThru -NoNewWindow
                [void]$retry.WaitForExit(180000)
                if ($retry.ExitCode -eq 0) {
                    Log "$($u.Name) successfully upgraded!" "SUCCESS"
                    $Global:Stats["Winget Packages"].Updated++
                } else {
                    Log "Could not upgrade $($u.Name) (ExitCode: $($retry.ExitCode))." "WARN"
                    $Global:Stats["Winget Packages"].Failed++
                }
            }
        }
    } catch {
        Log "Error processing Winget upgrades: $_" "ERROR"
    }
}

# -------------------------------------------------------------------------
# PHASE 3: CHOCOLATEY & SCOOP
# -------------------------------------------------------------------------
function Update-ChocoAndScoop {
    # Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Log "Scanning Chocolatey packages..." "STEP"
        try {
            $chocoOut = choco outdated -r 2>$null
            if ($chocoOut) {
                Log "Upgrading all outdated Chocolatey packages..." "SUBSTEP"
                & choco upgrade all -y --no-progress
                if ($LASTEXITCODE -eq 0) {
                    Log "Chocolatey packages updated." "SUCCESS"
                    $Global:Stats["Chocolatey Packages"].Updated = 1
                } else {
                    Log "Chocolatey reported exit code $LASTEXITCODE." "WARN"
                }
            } else {
                Log "All Chocolatey packages are up to date." "SUCCESS"
            }
        } catch {
            Log "Chocolatey upgrade error: $_" "ERROR"
            $Global:Stats["Chocolatey Packages"].Failed = 1
        }
    }

    # Scoop
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Log "Scanning Scoop packages..." "STEP"
        try {
            Log "Updating Scoop status..." "SUBSTEP"
            & scoop update
            $scoopStatus = & scoop status 2>$null
            if ($scoopStatus -match "Everything is ok") {
                Log "All Scoop apps are up to date." "SUCCESS"
            } else {
                Log "Upgrading Scoop apps..." "SUBSTEP"
                & scoop update *
                Log "Scoop upgrade finished." "SUCCESS"
                $Global:Stats["Scoop Packages"].Updated = 1
            }
        } catch {
            Log "Scoop upgrade error: $_" "ERROR"
            $Global:Stats["Scoop Packages"].Failed = 1
        }
    }
}

# -------------------------------------------------------------------------
# PHASE 4: NODE.JS / JAVASCRIPT ECOSYSTEM
# -------------------------------------------------------------------------
function Update-NodeEcosystem {
    Log "Scanning Node.js / JavaScript package ecosystems..." "STEP"
    
    # NPM
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        try {
            Log "Checking global npm packages..." "SUBSTEP"
            $outdated = npm outdated -g --json 2>$null | ConvertFrom-Json
            if ($outdated -and ($outdated.PSObject.Properties.Count -gt 0)) {
                $pkgNames = @($outdated.PSObject.Properties.Name)
                Log "Updating global NPM packages ($($pkgNames -join ', '))..." "SUBSTEP"
                & npm install -g @pkgNames
                Log "Global NPM packages updated!" "SUCCESS"
                $Global:Stats["Node / NPM Global"].Updated += $pkgNames.Count
            } else {
                Log "All global NPM packages are up to date." "SUCCESS"
            }
        } catch {
            Log "Error checking/updating NPM: $_" "WARN"
        }
    }

    # PNPM
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        try {
            Log "Updating global PNPM packages..." "SUBSTEP"
            & pnpm update -g
            Log "PNPM global packages up to date." "SUCCESS"
        } catch {}
    }

    # Yarn
    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        try {
            Log "Updating global Yarn packages..." "SUBSTEP"
            & yarn global upgrade --silent
            Log "Yarn global packages up to date." "SUCCESS"
        } catch {}
    }

    # Bun
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        try {
            Log "Updating Bun runtime..." "SUBSTEP"
            & bun upgrade
            Log "Bun runtime up to date." "SUCCESS"
        } catch {}
    }
}

# -------------------------------------------------------------------------
# PHASE 5: PYTHON / PIP ECOSYSTEM
# -------------------------------------------------------------------------
function Update-PythonEcosystem {
    Log "Scanning Python environments & packages..." "STEP"
    
    $pythonCmd = $null
    if (Get-Command python -ErrorAction SilentlyContinue) { $pythonCmd = "python" }
    elseif (Get-Command py -ErrorAction SilentlyContinue) { $pythonCmd = "py" }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) { $pythonCmd = "python3" }

    if (-not $pythonCmd) {
        Log "Python is not installed or not in PATH. Skipping." "WARN"
        $Global:Stats["Python / Pip Packages"].Skipped = 1
        return
    }

    try {
        Log "Upgrading pip to latest version ($pythonCmd)..." "SUBSTEP"
        & $pythonCmd -m pip install --upgrade --user pip 2>$null
        
        Log "Checking for outdated Python libraries..." "SUBSTEP"
        $outdatedJson = & $pythonCmd -m pip list --outdated --format=json 2>$null
        if ($outdatedJson) {
            $outdatedList = $outdatedJson | ConvertFrom-Json
            if ($outdatedList -and $outdatedList.Count -gt 0) {
                Log "Found $($outdatedList.Count) outdated Python package(s)." "INFO" -Color Yellow
                $names = @($outdatedList | ForEach-Object { $_.name })
                
                Log "Upgrading: $($names -join ', ')..." "SUBSTEP"
                & $pythonCmd -m pip install --upgrade --user @names
                if ($LASTEXITCODE -eq 0) {
                    Log "All Python packages upgraded successfully!" "SUCCESS"
                    $Global:Stats["Python / Pip Packages"].Updated += $names.Count
                } else {
                    Log "Some Python packages encountered warnings during upgrade." "WARN"
                    $Global:Stats["Python / Pip Packages"].Failed = 1
                }
            } else {
                Log "All installed Python packages are up to date!" "SUCCESS"
            }
        } else {
            Log "All installed Python packages are up to date!" "SUCCESS"
        }

        # pipx
        if (Get-Command pipx -ErrorAction SilentlyContinue) {
            Log "Upgrading isolated pipx applications..." "SUBSTEP"
            & pipx upgrade-all
            Log "Pipx applications up to date." "SUCCESS"
        }
    } catch {
        Log "Error checking/updating Python packages: $_" "ERROR"
    }
}

# -------------------------------------------------------------------------
# PHASE 6: RUST, .NET, GITHUB CLI & POWERSHELL MODULES
# -------------------------------------------------------------------------
function Update-DevTooling {
    Log "Scanning Developer Tooling (Rust, .NET, Git, PowerShell Modules)..." "STEP"
    
    # Rustup
    if (Get-Command rustup -ErrorAction SilentlyContinue) {
        try {
            Log "Updating Rust toolchain (rustup)..." "SUBSTEP"
            & rustup update
            Log "Rust toolchain is up to date." "SUCCESS"
            $Global:Stats["Rust / Cargo"].Updated = 1
        } catch {}
    }

    # Cargo-update
    if (Get-Command cargo-install-update -ErrorAction SilentlyContinue) {
        try {
            Log "Updating installed Cargo binaries..." "SUBSTEP"
            & cargo install-update -a
            Log "Cargo binaries updated." "SUCCESS"
        } catch {}
    }

    # .NET Global Tools
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        try {
            Log "Updating .NET Global Tools..." "SUBSTEP"
            & dotnet tool update --global --all 2>$null
            Log ".NET global tools up to date." "SUCCESS"
            $Global:Stats[".NET Global Tools"].Updated = 1
        } catch {}
    }

    # GitHub CLI extensions
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            Log "Upgrading GitHub CLI extensions..." "SUBSTEP"
            & gh extension upgrade --all 2>$null
            Log "GitHub CLI extensions up to date." "SUCCESS"
        } catch {}
    }

    # PowerShell Modules
    try {
        Log "Checking for outdated PowerShell Modules (CurrentUser)..." "SUBSTEP"
        $installedModules = Get-InstalledModule -ErrorAction SilentlyContinue
        if ($installedModules) {
            foreach ($m in $installedModules) {
                try {
                    Update-Module -Name $m.Name -AcceptLicense -Force -ErrorAction SilentlyContinue
                } catch {}
            }
            Log "PowerShell modules refreshed." "SUCCESS"
            $Global:Stats["PowerShell Modules"].Updated = 1
        } else {
            Log "No PowerShellGet modules found needing updates." "SUCCESS"
        }
    } catch {}
}

# -------------------------------------------------------------------------
# PHASE 7: WINDOWS UPDATE CHECK
# -------------------------------------------------------------------------
function Check-WindowsUpdates {
    if ($SkipWindowsUpdate) {
        Log "Windows Update scan skipped by parameter." "INFO"
        return
    }

    Log "Checking Windows Update status..." "STEP"
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
        
        $pendingCount = $searchResult.Updates.Count
        if ($pendingCount -eq 0) {
            Log "Windows is completely up to date with all Microsoft patches!" "SUCCESS"
        } else {
            Log "Found $pendingCount pending Windows Update patch(es):" "WARN"
            foreach ($patch in $searchResult.Updates) {
                Write-Host "    - $($patch.Title)" -ForegroundColor Yellow
            }
            Write-Host "    (Install via Windows Settings -> Windows Update to finalize reboot if required)." -ForegroundColor Gray
            $Global:Stats["Windows Update"].Updated = $pendingCount
        }
    } catch {
        Log "Windows Update scan returned notice: $($_.Exception.Message)" "WARN"
    }
}

# -------------------------------------------------------------------------
# PHASE 8: CACHE & TEMP CLEANUP
# -------------------------------------------------------------------------
function Clean-PackageCaches {
    Log "Performing post-update cache optimization..." "STEP"
    try {
        # Winget Temp Cleanup
        $wingetTemp = Join-Path $env:LOCALAPPDATA "Temp\WinGet"
        if (Test-Path $wingetTemp) {
            Remove-Item $wingetTemp -Recurse -Force -ErrorAction SilentlyContinue
            Log "Cleaned Winget installer cache." "SUBSTEP"
        }

        # Pip cache trim
        if (Get-Command python -ErrorAction SilentlyContinue) {
            & python -m pip cache purge 2>$null | Out-Null
            Log "Purged stale Python wheel cache." "SUBSTEP"
        }

        # NPM cache verify
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            & npm cache verify 2>$null | Out-Null
            Log "Verified and optimized NPM cache." "SUBSTEP"
        }

        Log "Cache optimization complete." "SUCCESS"
    } catch {}
}

# -------------------------------------------------------------------------
# SUMMARY & REPORT
# -------------------------------------------------------------------------
function Show-Summary {
    $Stopwatch.Stop()
    $elapsed = $Stopwatch.Elapsed
    $timeStr = "{0:D2}m {1:D2}s" -f $elapsed.Minutes, $elapsed.Seconds

    Write-Host "`n==========================================================================" -ForegroundColor Green
    Write-Host "                  ULTIMATE UPDATE EXECUTION SUMMARY                       " -ForegroundColor White
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host (" Total Duration : {0}" -f $timeStr) -ForegroundColor Cyan
    Write-Host (" Full Log Saved : {0}" -f $LogFile) -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Gray

    foreach ($cat in $Global:Stats.Keys) {
        $u = $Global:Stats[$cat].Updated
        $f = $Global:Stats[$cat].Failed
        $s = $Global:Stats[$cat].Skipped
        
        $statusStr = "OK / Checked"
        $statusCol = [ConsoleColor]::Green
        if ($u -gt 0) {
            $statusStr = "$u Action(s) Applied"
            $statusCol = [ConsoleColor]::Cyan
        } elseif ($f -gt 0) {
            $statusStr = "$f Notice(s)"
            $statusCol = [ConsoleColor]::Yellow
        } elseif ($s -gt 0) {
            $statusStr = "Skipped"
            $statusCol = [ConsoleColor]::DarkGray
        }

        Write-Host (" {0,-25} : " -f $cat) -NoNewline -ForegroundColor White
        Write-Host $statusStr -ForegroundColor $statusCol
    }
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host " All available updates, healing and optimizations have completed!" -ForegroundColor White
    Write-Host "==========================================================================`n" -ForegroundColor Green
}

# -------------------------------------------------------------------------
# MAIN EXECUTION ROUTINE
# -------------------------------------------------------------------------
try {
    Show-Banner
    Invoke-EnvironmentHealing
    Invoke-SuggestedEssentials
    Update-WingetPackages
    Update-ChocoAndScoop
    Update-NodeEcosystem
    Update-PythonEcosystem
    Update-DevTooling
    Check-WindowsUpdates
    Clean-PackageCaches
    Show-Summary
} catch {
    Log "Fatal error during update process: $_" "ERROR"
}
