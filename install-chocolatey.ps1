#Requires -Version 5.1

###############################################################################
# 🛠️ Chocolatey Installer Script for Windows
# ------------------------------------------
# This script installs Chocolatey on Windows and ensures:
#   - Chocolatey is properly installed and configured
#   - PowerShell execution policy is set correctly
#   - It runs `choco doctor` for a health check
#   - Logs all activity to $env:USERPROFILE\Logs\ChocolateyInstall.log
#
# ✅ Safe to run multiple times — it skips install if Chocolatey is already present
#
# 🔧 USAGE INSTRUCTIONS:
# 1. Open PowerShell as Administrator
# 2. Navigate to the script directory:
#      cd C:\path\to\chocolateyScripts
# 3. Set execution policy (if needed):
#      Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# 4. Run the script:
#      .\install-chocolatey.ps1
#
# 📁 Log output is saved to:
#      $env:USERPROFILE\Logs\ChocolateyInstall.log
#
# ℹ️ Compatible with:
#   - Windows 10, Windows 11
#   - PowerShell 5.1 or higher
#   - Administrator privileges required
#
# 🚨 Notes and Warnings:
# - You must run PowerShell as Administrator
# - After installation, restart PowerShell or run:
#     refreshenv
#
# 🧪 Troubleshooting:
# - Check the log file if you don't see Chocolatey working:
#     $env:USERPROFILE\Logs\ChocolateyInstall.log
#
# 🖥️ Windows Features:
# - Automatically sets PowerShell execution policy
# - Configures Chocolatey environment variables
# - Handles Windows-specific installation requirements
###############################################################################

# Set up logging
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\ChocolateyInstall.log"
Add-Content -Path $LogFile -Value "Starting Chocolatey setup at $(Get-Date)"

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

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if Chocolatey is already installed
function Test-ChocolateyInstalled {
    try {
        $null = Get-Command choco -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Set PowerShell execution policy
function Set-ExecutionPolicySafe {
    Write-Status "Setting PowerShell execution policy..."
    
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($currentPolicy -eq "Restricted") {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Success "Execution policy set to RemoteSigned"
        }
        else {
            Write-Success "Execution policy already set to $currentPolicy"
        }
    }
    catch {
        Write-Warning "Could not set execution policy: $($_.Exception.Message)"
    }
}

# Install Chocolatey
function Install-Chocolatey {
    Write-Status "Installing Chocolatey..."
    
    try {
        # Download and run the Chocolatey installation script
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        if (Test-ChocolateyInstalled) {
            Write-Success "Chocolatey installed successfully"
            return $true
        }
        else {
            Write-Error "Chocolatey installation failed"
            return $false
        }
    }
    catch {
        Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
        return $false
    }
}

# Configure Chocolatey environment
function Configure-ChocolateyEnvironment {
    Write-Status "Configuring Chocolatey environment..."
    
    try {
        # Refresh environment variables
        refreshenv
        
        # Test Chocolatey installation
        $chocoVersion = choco --version
        Write-Success "Chocolatey version: $chocoVersion"
        
        # Set Chocolatey configuration
        choco feature enable -n allowGlobalConfirmation
        Write-Success "Global confirmation enabled"
        
        return $true
    }
    catch {
        Write-Warning "Could not configure Chocolatey environment: $($_.Exception.Message)"
        return $false
    }
}

# Run Chocolatey doctor
function Run-ChocolateyDoctor {
    Write-Status "Running choco doctor..."
    
    try {
        $doctorOutput = choco doctor 2>&1
        Add-Content -Path $LogFile -Value "Chocolatey doctor output:"
        Add-Content -Path $LogFile -Value $doctorOutput
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Chocolatey doctor completed successfully"
        }
        else {
            Write-Warning "Chocolatey doctor found issues (check log for details)"
        }
    }
    catch {
        Write-Warning "Could not run choco doctor: $($_.Exception.Message)"
    }
}

# Main execution
function Main {
    Write-Status "Chocolatey installer started at $(Get-Date)"
    
    # Check if running as Administrator
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator. Please right-click PowerShell and select 'Run as Administrator'."
        exit 1
    }
    
    Write-Success "Running as Administrator - proceeding with installation"
    
    # Check if Chocolatey is already installed
    if (Test-ChocolateyInstalled) {
        Write-Success "Chocolatey is already installed."
        $version = choco --version
        Write-Success "Chocolatey version: $version"
        
        # Still run configuration and doctor
        Configure-ChocolateyEnvironment
        Run-ChocolateyDoctor
        
        Write-Success "Chocolatey setup complete at $(Get-Date)"
        return
    fi
    
    # Set execution policy
    Set-ExecutionPolicySafe
    
    # Install Chocolatey
    if (Install-Chocolatey) {
        # Configure environment
        Configure-ChocolateyEnvironment
        
        # Run doctor
        Run-ChocolateyDoctor
        
        Write-Success "Chocolatey installation complete at $(Get-Date)"
        Write-Status "Next steps:"
        Write-Status "1. Restart PowerShell or run 'refreshenv'"
        Write-Status "2. Test installation: choco --version"
        Write-Status "3. Check log file: $LogFile"
    }
    else {
        Write-Error "Chocolatey installation failed. Check log file: $LogFile"
        exit 1
    }
}

# Run main function
Main 