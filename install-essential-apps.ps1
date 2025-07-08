#Requires -Version 5.1

###############################################################################
# 🛠️ Essential Apps Installer Script for Windows
# ----------------------------------------------
# This script installs essential applications using Chocolatey:
#   - Google Chrome (Web browser)
#   - Mozilla Firefox (Web browser)
#   - Microsoft Edge (Web browser)
#   - Visual Studio Code (Code editor)
#   - Notepad++ (Text editor)
#   - 7-Zip (File compression)
#   - VLC Media Player (Media player)
#   - Discord (Communication)
#   - Steam (Gaming platform)
#   - Windows Terminal (Terminal emulator)
#
# ✅ Safe to run multiple times — it skips apps that are already installed
# ✅ Logs all activity for troubleshooting
# ✅ Provides progress feedback
#
# 🔧 USAGE INSTRUCTIONS:
# 1. Make sure Chocolatey is installed first:
#      .\install-chocolatey.ps1
# 2. Run this script:
#      .\install-essential-apps.ps1
#
# 📁 Log output is saved to:
#      $env:USERPROFILE\Logs\EssentialAppsInstall.log
#
# ℹ️ Requirements:
#   - Chocolatey must be installed
#   - Windows with Administrator privileges
#
# 🚨 Notes:
# - Some apps may require manual setup after installation
# - You may be prompted for confirmation during installation
# - Large downloads may take time depending on your internet speed
###############################################################################

# Set up logging
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\EssentialAppsInstall.log"
Add-Content -Path $LogFile -Value "Starting Essential Apps installation at $(Get-Date)"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Blue
    Add-Content -Path $LogFile -Value "[INFO] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Green
    Add-Content -Path $LogFile -Value "[SUCCESS] $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
    Add-Content -Path $LogFile -Value "[WARNING] $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
    Add-Content -Path $LogFile -Value "[ERROR] $Message"
}

# Check if Chocolatey is installed
function Test-ChocolateyInstalled {
    try {
        $null = Get-Command choco -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to install an app if not already installed
function Install-App {
    param(
        [string]$AppName,
        [string]$ChocoPackage,
        [string]$DisplayName
    )
    
    Write-Status "Checking $DisplayName..."
    
    # Check if app is already installed via Chocolatey
    $installed = choco list --local-only $ChocoPackage --limit-output
    if ($installed -match $ChocoPackage) {
        Write-Success "$DisplayName is already installed via Chocolatey"
        return $true
    }
    
    # Check if app exists in Program Files
    $programFiles = @("$env:ProgramFiles\$AppName", "$env:ProgramFiles(x86)\$AppName")
    foreach ($path in $programFiles) {
        if (Test-Path $path) {
            Write-Warning "$DisplayName is already installed in $path"
            return $true
        }
    }
    
    # Install the app
    Write-Status "Installing $DisplayName..."
    try {
        choco install $ChocoPackage -y | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$DisplayName installed successfully"
            return $true
        }
        else {
            Write-Error "Failed to install $DisplayName"
            return $false
        }
    }
    catch {
        Write-Error "Failed to install $DisplayName: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Main {
    Write-Status "Essential Apps installer started at $(Get-Date)"
    
    # Check if running as Administrator
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator. Please right-click PowerShell and select 'Run as Administrator'."
        exit 1
    }
    
    # Check if Chocolatey is installed
    if (-not (Test-ChocolateyInstalled)) {
        Write-Error "Chocolatey is not installed. Please run .\install-chocolatey.ps1 first."
        exit 1
    }
    
    Write-Success "Chocolatey is available. Starting app installation..."
    
    # Update Chocolatey before installing
    Write-Status "Updating Chocolatey..."
    try {
        choco upgrade all -y | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Chocolatey updated successfully"
        }
        else {
            Write-Warning "Chocolatey update failed, but continuing with installation"
        }
    }
    catch {
        Write-Warning "Chocolatey update failed, but continuing with installation"
    }
    
    # Install applications
    Write-Status "Starting application installations..."
    
    $apps = @(
        @{Name="Google Chrome"; Package="googlechrome"; Display="Google Chrome"},
        @{Name="Mozilla Firefox"; Package="firefox"; Display="Mozilla Firefox"},
        @{Name="Microsoft Edge"; Package="microsoft-edge"; Display="Microsoft Edge"},
        @{Name="Visual Studio Code"; Package="vscode"; Display="Visual Studio Code"},
        @{Name="Notepad++"; Package="notepadplusplus"; Display="Notepad++"},
        @{Name="7-Zip"; Package="7zip"; Display="7-Zip"},
        @{Name="VLC Media Player"; Package="vlc"; Display="VLC Media Player"},
        @{Name="Discord"; Package="discord"; Display="Discord"},
        @{Name="Steam"; Package="steam"; Display="Steam"},
        @{Name="Windows Terminal"; Package="microsoft-windows-terminal"; Display="Windows Terminal"}
    )
    
    $installedApps = @()
    $failedApps = @()
    
    foreach ($app in $apps) {
        if (Install-App -AppName $app.Name -ChocoPackage $app.Package -DisplayName $app.Display) {
            $installedApps += $app.Display
        }
        else {
            $failedApps += $app.Display
        }
    }
    
    # Post-installation summary
    Write-Status "Installation complete! Summary:"
    Write-Host "----------------------------------------"
    Add-Content -Path $LogFile -Value "----------------------------------------"
    
    foreach ($app in $apps) {
        $installed = choco list --local-only $app.Package --limit-output
        if ($installed -match $app.Package) {
            Write-Success "✓ $($app.Display)"
        }
        else {
            Write-Error "✗ $($app.Display)"
        }
    }
    
    Write-Host ""
    Add-Content -Path $LogFile -Value ""
    Write-Status "Installation Summary:"
    Write-Success "Successfully installed/verified: $($installedApps.Count) apps"
    
    if ($failedApps.Count -gt 0) {
        Write-Warning "Failed to install: $($failedApps.Count) apps"
        foreach ($app in $failedApps) {
            Write-Warning "  - $app"
        }
    }
    
    Write-Host ""
    Add-Content -Path $LogFile -Value ""
    Write-Status "Next steps:"
    Write-Status "1. Check your Start Menu for newly installed apps"
    Write-Status "2. Some apps may require additional setup or login"
    Write-Status "3. You may need to grant permissions in Windows Security"
    Write-Status "4. For troubleshooting, check the log file: $LogFile"
    
    Write-Success "Essential apps installation completed at $(Get-Date)"
}

# Run main function
Main 