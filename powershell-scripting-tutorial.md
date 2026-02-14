# PowerShell Scripting Tutorial: Learning from Chocolatey Scripts

This tutorial uses the Chocolatey automation scripts as a practical example to teach PowerShell scripting concepts. You'll learn by examining real-world code that solves actual problems.

## Learning Path

### Beginner Level
1. [Basic Script Structure](#1-basic-script-structure)
2. [Variables and Configuration](#2-variables-and-configuration)
3. [Functions and Modularity](#3-functions-and-modularity)
4. [User Input and Interaction](#4-user-input-and-interaction)

### Intermediate Level
5. [Error Handling and Validation](#5-error-handling-and-validation)
6. [Logging and Debugging](#6-logging-and-debugging)
7. [System Detection and Adaptation](#7-system-detection-and-adaptation)
8. [Configuration Management](#8-configuration-management)

### Advanced Level
9. [Process Management and Automation](#9-process-management-and-automation)
10. [Testing and Safety Checks](#10-testing-and-safety-checks)
11. [Security and Safety Patterns](#11-security-and-safety-patterns)
12. [Documentation and Maintenance](#12-documentation-and-maintenance)

## 1. Basic Script Structure

### The Requires Statement
```powershell
#Requires -Version 5.1
```
**What it does:** Ensures the script only runs on PowerShell 5.1 or later.
**Why it matters:** Prevents confusing errors on older systems that lack features your script needs.

### Script Metadata (Comment-Based Help)
```powershell
<#
.SYNOPSIS
    Installs Chocolatey package manager for Windows.

.DESCRIPTION
    This script installs Chocolatey with proper configuration and runs health checks.
    Safe to run multiple times - skips installation if already present.

.NOTES
    Requires Administrator privileges.
    Logs to: $env:USERPROFILE\Logs\ChocolateyInstall.log
#>
```
**Best Practice:** Always include `.SYNOPSIS`, `.DESCRIPTION`, and `.NOTES` so users can run `Get-Help .\your-script.ps1` and understand what it does.

### Administrator Check
```powershell
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    exit 1
}
```
**Why it matters:** Chocolatey installs system-wide software. Running without admin rights would fail partway through, leaving things in a broken state.

**Exercise:** Try running a script without admin rights and observe the error messages.

## 2. Variables and Configuration

### Automatic Variables
```powershell
# Built-in variables PowerShell provides
$env:USERPROFILE     # C:\Users\YourName
$env:COMPUTERNAME    # Your PC name
$PSScriptRoot        # Folder where the script lives
```

### Script Variables
```powershell
# Configuration values
$WifiNetwork = "YOUR_WIFI_NAME"
$MaxRetries = 3
$RetryDelay = 300  # 5 minutes in seconds

# Paths
$LogPath = "$env:USERPROFILE\Logs"
$LogFile = "$LogPath\AutoUpdateChocolatey.log"
```

### Reading from a Config File
```powershell
# Load settings from an external JSON file
$configPath = Join-Path $PSScriptRoot "config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $WifiNetwork = $config.wifiNetwork
    $MaxRetries = $config.maxRetries
}
```

**Key Concept:** Keeping settings in a config file means you never need to edit the script itself. Copy `config.example.json` to `config.json` and customize.

**Exercise:** Create a simple JSON config file and load it into a PowerShell variable.

## 3. Functions and Modularity

### Function Design Principles
```powershell
# Good: Clear name, parameter block, single responsibility
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    Add-Content -Path $LogFile -Value "[INFO] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Add-Content -Path $LogFile -Value "[SUCCESS] $Message"
}
```

### Functions with Multiple Parameters
```powershell
function Send-EmailNotification {
    param(
        [string]$Subject,
        [string]$Body
    )

    try {
        $smtp = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
        $smtp.EnableSsl = $true
        # ... send the message ...
        Write-Success "Email notification sent"
    }
    catch {
        Write-Error "Failed to send email: $($_.Exception.Message)"
    }
}
```

**Key Concepts:**
- **Single Responsibility:** Each function does one thing well
- **Named Parameters:** Use `param()` blocks for clarity
- **Error Handling:** Wrap risky operations in `try/catch`
- **Consistent Output:** Use helper functions for uniform messaging

**Exercise:** Write a function that takes a file path and returns `$true` if the file exists and is not empty.

## 4. User Input and Interaction

### Colored Console Output
```powershell
# Color-coded messages help users scan output quickly
Write-Host "[INFO] Checking system..." -ForegroundColor Blue
Write-Host "[SUCCESS] All checks passed" -ForegroundColor Green
Write-Host "[WARNING] Package is outdated" -ForegroundColor Yellow
Write-Host "[ERROR] Installation failed" -ForegroundColor Red
```

### Interactive Prompts
```powershell
# Simple yes/no prompt
$response = Read-Host "Do you want to continue? (Y/N)"
if ($response -eq 'Y') {
    # proceed
}

# Menu-driven selection
Write-Host "Select an option:"
Write-Host "  1. Install Chocolatey"
Write-Host "  2. Update all packages"
Write-Host "  3. Run health check"
$choice = Read-Host "Enter your choice (1-3)"
```

**Learning Points:**
- **Color coding** makes output scannable at a glance
- **Read-Host** pauses the script and waits for user input
- **Menus** guide users through multi-step processes

**Exercise:** Create a menu function that presents 4 options and validates the user's selection.

## 5. Error Handling and Validation

### Defensive Programming
```powershell
# Check prerequisites before doing anything
function Test-Prerequisites {
    $errors = 0

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.1 or later is required"
        $errors++
    }

    # Check internet connectivity
    if (-not (Test-Connection -ComputerName "chocolatey.org" -Count 1 -Quiet)) {
        Write-Error "No internet connection detected"
        $errors++
    }

    # Check disk space (need at least 1 GB)
    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeGB -lt 1) {
        Write-Error "Only $freeGB GB free. Need at least 1 GB."
        $errors++
    }

    return $errors -eq 0
}
```

### Retry Logic with Backoff
```powershell
function Test-WifiNetwork {
    $retryCount = 0

    while ($retryCount -lt $MaxRetries) {
        try {
            # Check if connected to the right network
            $wifi = netsh wlan show interfaces |
                    Select-String "^\s*SSID\s*:" |
                    ForEach-Object { ($_ -split ":\s*", 2)[1].Trim() }

            if ($wifi -eq $WifiNetwork) {
                Write-Success "Connected to $WifiNetwork"
                return $true
            }
        }
        catch {
            Write-Warning "WiFi check failed, retrying..."
        }

        $retryCount++
        Start-Sleep -Seconds $RetryDelay
    }

    Write-Error "Not connected to $WifiNetwork after $MaxRetries attempts"
    return $false
}
```

**Key Patterns:**
- **Check early, fail fast:** Validate the environment before starting real work
- **Accumulate errors:** Report all problems at once instead of stopping at the first
- **Retry transient failures:** Network issues are often temporary

## 6. Logging and Debugging

### Simple File Logging
```powershell
# Create log directory if it doesn't exist
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\ChocolateyInstall.log"
Add-Content -Path $LogFile -Value "Starting setup at $(Get-Date)"
```

### Dual Output (Console + File)
```powershell
function Write-Status {
    param([string]$Message)
    # Show in console with color
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    # Also write to log file (no color codes)
    Add-Content -Path $LogFile -Value "[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}
```

**Learning Points:**
- **Always log to a file** so you can review what happened after the fact
- **Timestamps** are essential for debugging timing issues
- **Dual output** keeps the user informed while preserving a permanent record

## 7. System Detection and Adaptation

### Power Status Detection
```powershell
function Test-ACPower {
    try {
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop
        if ($battery) {
            # BatteryStatus >= 2 means plugged into AC power
            return $battery.BatteryStatus -ge 2
        }
        # No battery = desktop = always on power
        return $true
    }
    catch {
        # Fallback for older systems
        $battery = Get-WmiObject Win32_Battery
        if ($battery) {
            return $battery.BatteryStatus -ge 2
        }
        return $true
    }
}
```

### Network Detection
```powershell
function Test-WifiNetwork {
    # Get wireless adapter info
    $adapters = Get-CimInstance -ClassName Win32_NetworkAdapter |
                Where-Object { $_.NetConnectionStatus -eq 2 -and
                               $_.Description -match "Wireless|Wi-Fi" }

    if (-not $adapters) {
        Write-Warning "No active wireless adapter found"
        return $false
    }

    # Check the connected SSID
    $ssid = netsh wlan show interfaces |
            Select-String "^\s*SSID\s*:" |
            ForEach-Object { ($_ -split ":\s*", 2)[1].Trim() }

    return $ssid -eq $WifiNetwork
}
```

**Concepts Demonstrated:**
- **CIM over WMI:** `Get-CimInstance` is the modern replacement for `Get-WmiObject`
- **Graceful fallbacks:** Try the modern approach first, fall back to legacy if needed
- **Environment awareness:** Check power and network before running long operations

## 8. Configuration Management

### JSON Configuration Files
```json
{
  "wifiNetwork": "YOUR_WIFI_NAME",
  "maxRetries": 3,
  "retryDelaySeconds": 300,
  "notifications": {
    "enableToastNotifications": true,
    "notifyOnSuccess": true,
    "notifyOnError": true
  },
  "backupSettings": {
    "backupPath": "%USERPROFILE%\\Documents\\ChocolateyBackups",
    "keepBackups": 5
  }
}
```

### Loading and Using Config
```powershell
$configPath = Join-Path $PSScriptRoot "config.json"

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Status "Loaded configuration from $configPath"
} else {
    Write-Warning "No config.json found. Using defaults."
    Write-Warning "Copy config.example.json to config.json to customize."
}
```

**Best Practice:** Ship a `config.example.json` with safe placeholder values. Users copy it to `config.json` and customize. The real `config.json` is git-ignored so personal settings stay private.

## 9. Process Management and Automation

### Windows Scheduled Tasks
```powershell
# Create a scheduled task for automatic updates
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-File `"$PSScriptRoot\auto-update-chocolatey.ps1`""

$trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"

$settings = New-ScheduledTaskSettingsSet `
    -RunOnlyIfNetworkAvailable `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName "Chocolatey Auto Update" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -RunLevel Highest
```

### Idempotent Operations
```powershell
# Safe to run multiple times - checks before acting
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Success "Chocolatey is already installed"
} else {
    Write-Status "Installing Chocolatey..."
    # install logic here
}
```

**Key Concept:** Scripts that can be run repeatedly without causing problems are called *idempotent*. Always check the current state before making changes.

## 10. Testing and Safety Checks

### Validation Scripts
```powershell
# validate-setup.ps1 checks everything is configured correctly
function Test-Configuration {
    $configPath = Join-Path $PSScriptRoot "config.json"

    if (-not (Test-Path $configPath)) {
        Write-Fail "config.json is missing"
        return $false
    }

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Pass "config.json has valid JSON syntax"
    }
    catch {
        Write-Fail "config.json has invalid JSON: $($_.Exception.Message)"
        return $false
    }

    # Check for placeholder values that need customizing
    if ($config.wifiNetwork -eq "YOUR_WIFI_NAME") {
        Write-Warn "WiFi network is still set to the placeholder value"
    }

    return $true
}
```

**Exercise:** Write a validation function that checks whether Chocolatey is installed and reports its version.

## 11. Security and Safety Patterns

### Execution Policy Awareness
```powershell
# Check if scripts are allowed to run
$policy = Get-ExecutionPolicy
if ($policy -eq "Restricted") {
    Write-Warning "PowerShell execution policy is Restricted."
    Write-Warning "Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
    exit 1
}
```

### Safe Package Installation
```powershell
# Install with confirmation and error handling
function Install-ChocolateyPackage {
    param([string]$PackageName)

    try {
        choco install $PackageName -y --no-progress
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$PackageName installed successfully"
        } else {
            Write-Error "$PackageName installation returned exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "Failed to install $PackageName : $($_.Exception.Message)"
    }
}
```

**Security Tips:**
- **Review scripts before running** — never blindly execute code from the internet
- **Use `-WhatIf`** where supported to preview changes
- **Run as admin only when necessary** — don't stay elevated for tasks that don't need it
- **Keep Chocolatey updated** — `choco upgrade chocolatey` patches security issues

## 12. Documentation and Maintenance

### Comment-Based Help
```powershell
<#
.SYNOPSIS
    One-line description of what the script does.

.DESCRIPTION
    Detailed explanation of behavior, prerequisites, and side effects.

.PARAMETER Name
    Description of each parameter the script accepts.

.EXAMPLE
    .\install-chocolatey.ps1
    Installs Chocolatey with default settings.

.NOTES
    Author, version, and any important caveats.
#>
```

### Inline Comments
```powershell
# Good: Explain WHY, not WHAT
# BatteryStatus >= 2 means AC power (1 = discharging, 2+ = charging/plugged in)
return $battery.BatteryStatus -ge 2

# Bad: Just restating the code
# Check if status is greater than or equal to 2
return $battery.BatteryStatus -ge 2
```

## Practical Exercises

### Exercise 1: Directory Setup
Write a function that ensures a directory exists and creates it if it doesn't:

```powershell
function Ensure-Directory {
    param([string]$Path)
    # Your code here
}
```

### Exercise 2: Config Validation
Create a function that loads a JSON config file and checks for required keys:

```powershell
function Test-ConfigFile {
    param([string]$Path)
    # Your code here
}
```

### Exercise 3: Package Checker
Build a function that checks if a Chocolatey package is installed and reports its version:

```powershell
function Get-PackageStatus {
    param([string]$PackageName)
    # Your code here
}
```

## Next Steps

1. **Study the scripts** in this repository — they use all the patterns above
2. **Copy `config.example.json` to `config.json`** and customize it
3. **Run `validate-setup.ps1`** to check your environment
4. **Try modifying a script** and test your changes
5. **Share improvements** with the community

## Additional Resources

- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [Chocolatey Documentation](https://docs.chocolatey.org/)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) — Script analysis tool
- [PowerShell Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
