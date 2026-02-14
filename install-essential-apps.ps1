#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
    Installs essential Windows applications using Chocolatey.

.DESCRIPTION
    Installs browsers, development tools, utilities, and communication apps.
    Safe to run multiple times - skips already installed applications.

.NOTES
    Requires Chocolatey to be installed first.
    Logs to: $env:USERPROFILE\Logs\EssentialAppsInstall.log
#>

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

function Write-LogWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
    Add-Content -Path $LogFile -Value "[WARNING] $Message"
}

function Write-LogError {
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
    $installed = choco list $ChocoPackage --limit-output
    if ($installed -match $ChocoPackage) {
        Write-Success "$DisplayName is already installed via Chocolatey"
        return $true
    }
    
    # Check if app exists in Program Files
    $programFiles = @("$env:ProgramFiles\$AppName", "$env:ProgramFiles(x86)\$AppName")
    foreach ($path in $programFiles) {
        if (Test-Path $path) {
            Write-LogWarning "$DisplayName is already installed in $path"
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
            Write-LogError "Failed to install $DisplayName"
            return $false
        }
    }
    catch {
        Write-LogError "Failed to install $DisplayName: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Main {
    Write-Status "Essential Apps installer started at $(Get-Date)"
    
    # Check if running as Administrator
    if (-not (Test-Administrator)) {
        Write-LogError "This script must be run as Administrator. Please right-click PowerShell and select 'Run as Administrator'."
        exit 1
    }
    
    # Check if Chocolatey is installed
    if (-not (Test-ChocolateyInstalled)) {
        Write-LogError "Chocolatey is not installed. Please run .\install-chocolatey.ps1 first."
        exit 1
    }
    
    Write-Success "Chocolatey is available. Starting app installation..."
    
    # Update Chocolatey before installing
    Write-Status "Updating Chocolatey..."
    try {
        choco upgrade chocolatey -y | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Chocolatey updated successfully"
        }
        else {
            Write-LogWarning "Chocolatey update failed, but continuing with installation"
        }
    }
    catch {
        Write-LogWarning "Chocolatey update failed, but continuing with installation"
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
        @{Name="Windows Terminal"; Package="microsoft-windows-terminal"; Display="Windows Terminal"},
        @{Name="PowerShell Core"; Package="powershell-core"; Display="PowerShell 7+"},
        @{Name="Git"; Package="git"; Display="Git"}
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
        $installed = choco list $app.Package --limit-output
        if ($installed -match $app.Package) {
            Write-Success "✓ $($app.Display)"
        }
        else {
            Write-LogError "✗ $($app.Display)"
        }
    }
    
    Write-Host ""
    Add-Content -Path $LogFile -Value ""
    Write-Status "Installation Summary:"
    Write-Success "Successfully installed/verified: $($installedApps.Count) apps"
    
    if ($failedApps.Count -gt 0) {
        Write-LogWarning "Failed to install: $($failedApps.Count) apps"
        foreach ($app in $failedApps) {
            Write-LogWarning "  - $app"
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