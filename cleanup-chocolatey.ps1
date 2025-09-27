#Requires -Version 5.1

<#
.SYNOPSIS
    Performs comprehensive Chocolatey cleanup and maintenance.

.DESCRIPTION
    Removes old package versions, cleans cache, removes orphaned dependencies,
    and runs health checks.

.NOTES
    Safe to run multiple times.
    Logs to: $env:USERPROFILE\Logs\ChocolateyCleanup.log
#>

# Set up logging
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\ChocolateyCleanup.log"
Add-Content -Path $LogFile -Value "Starting Chocolatey cleanup at $(Get-Date)"

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

# Function to check if Chocolatey is installed
function Test-ChocolateyInstalled {
    try {
        $null = Get-Command choco -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to get disk usage before cleanup
function Get-DiskUsage {
    try {
        $chocoPath = "$env:ChocolateyInstall"
        if (Test-Path $chocoPath) {
            $usage = (Get-ChildItem $chocoPath -Recurse | Measure-Object -Property Length -Sum).Sum
            return [math]::Round($usage / 1MB, 2)
        }
        else {
            return 0
        }
    }
    catch {
        return 0
    }
}

# Function to perform cleanup operations
function Perform-Cleanup {
    $cleanupSummary = ""
    $errors = ""
    $successCount = 0
    $errorCount = 0
    
    Write-Status "Starting Chocolatey cleanup operations..."
    
    # Update Chocolatey first
    Write-Status "Updating Chocolatey..."
    try {
        choco upgrade chocolatey -y | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            $cleanupSummary += "✅ Chocolatey updated successfully<br>"
            $successCount++
        }
        else {
            $errors += "❌ Chocolatey update failed<br>"
            $errorCount++
        }
    }
    catch {
        $errors += "❌ Chocolatey update failed<br>"
        $errorCount++
    }
    
    # Clean up old versions
    Write-Status "Cleaning up old versions..."
    try {
        choco cleanup all -y | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            $cleanupSummary += "✅ Old versions cleaned up successfully<br>"
            $successCount++
        }
        else {
            $errors += "❌ Cleanup failed<br>"
            $errorCount++
        }
    }
    catch {
        $errors += "❌ Cleanup failed<br>"
        $errorCount++
    }
    
    # Remove orphaned packages
    Write-Status "Removing orphaned packages..."
    try {
        $orphaned = choco list --local-only | Where-Object { $_ -match "^\S+" } | ForEach-Object {
            $package = $_.Split()[0]
            $deps = choco list --local-only --limit-output | Where-Object { $_ -match $package }
            if ($deps.Count -eq 1) {
                return $package
            }
        }
        
        if ($orphaned) {
            foreach ($package in $orphaned) {
                choco uninstall $package -y | Tee-Object -FilePath $LogFile -Append
            }
            $cleanupSummary += "✅ Orphaned packages removed successfully<br>"
        }
        else {
            $cleanupSummary += "✅ No orphaned packages found<br>"
        }
        $successCount++
    }
    catch {
        $errors += "❌ Orphaned package removal failed<br>"
        $errorCount++
    }
    
    # Clean up cache
    Write-Status "Cleaning up cache..."
    try {
        $cachePath = "$env:ChocolateyInstall\lib"
        if (Test-Path $cachePath) {
            Get-ChildItem $cachePath -Directory | ForEach-Object {
                $packagePath = $_.FullName
                $nupkgFiles = Get-ChildItem $packagePath -Filter "*.nupkg" -Recurse
                foreach ($file in $nupkgFiles) {
                    Remove-Item $file.FullName -Force
                }
            }
            $cleanupSummary += "✅ Cache cleaned up successfully<br>"
            $successCount++
        }
        else {
            $cleanupSummary += "✅ No cache to clean<br>"
            $successCount++
        }
    }
    catch {
        $errors += "❌ Cache cleanup failed<br>"
        $errorCount++
    }
    
    # Run choco doctor for health check
    Write-Status "Running choco doctor for health check..."
    try {
        $doctorOutput = choco doctor 2>&1
        $doctorOutput | Tee-Object -FilePath $LogFile -Append
        
        if ($LASTEXITCODE -eq 0) {
            $cleanupSummary += "✅ Health check completed successfully<br>"
            $successCount++
        }
        else {
            $errors += "❌ Health check failed<br>"
            $errorCount++
        }
    }
    catch {
        $errors += "❌ Health check failed<br>"
        $errorCount++
    }
    
    # Return results
    return @{
        Summary = $cleanupSummary
        Errors = $errors
        SuccessCount = $successCount
        ErrorCount = $errorCount
    }
}

# Function to show cleanup statistics
function Show-CleanupStats {
    param(
        [double]$BeforeUsage,
        [double]$AfterUsage
    )
    
    Write-Host ""
    Write-Status "Cleanup Statistics:"
    Write-Host "Before cleanup: $BeforeUsage MB"
    Write-Host "After cleanup:  $AfterUsage MB"
    
    $spaceSaved = $BeforeUsage - $AfterUsage
    if ($spaceSaved -gt 0) {
        Write-Success "Space saved through cleanup: $([math]::Round($spaceSaved, 2)) MB"
    }
    else {
        Write-Status "No significant space saved"
    }
}

# Main execution
function Main {
    Write-Status "Chocolatey cleanup started at $(Get-Date)"
    
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
    
    Write-Success "Chocolatey is available. Starting cleanup..."
    
    # Get disk usage before cleanup
    Write-Status "Checking disk usage before cleanup..."
    $beforeUsage = Get-DiskUsage
    Write-Status "Current Chocolatey disk usage: $beforeUsage MB"
    
    # Perform cleanup operations
    $cleanupResults = Perform-Cleanup
    
    # Get disk usage after cleanup
    Write-Status "Checking disk usage after cleanup..."
    $afterUsage = Get-DiskUsage
    Write-Status "Chocolatey disk usage after cleanup: $afterUsage MB"
    
    # Show cleanup summary
    Write-Status "Cleanup complete! Summary:"
    Write-Host "----------------------------------------"
    Add-Content -Path $LogFile -Value "----------------------------------------"
    
    if ($cleanupResults.ErrorCount -eq 0) {
        Write-Success "✅ All cleanup operations completed successfully ($($cleanupResults.SuccessCount) operations)"
    }
    else {
        Write-Warning "⚠️ Some cleanup operations had issues ($($cleanupResults.SuccessCount)/$($cleanupResults.SuccessCount + $cleanupResults.ErrorCount) operations)"
        Write-Warning "Failed operations:"
        Write-Host $cleanupResults.Errors
        Add-Content -Path $LogFile -Value $cleanupResults.Errors
    }
    
    # Show cleanup statistics
    Show-CleanupStats -BeforeUsage $beforeUsage -AfterUsage $afterUsage
    
    Write-Host ""
    Add-Content -Path $LogFile -Value ""
    Write-Status "Next steps:"
    Write-Status "1. Your Chocolatey installation is now cleaned up"
    Write-Status "2. Check the log file for detailed information: $LogFile"
    Write-Status "3. Run this script periodically to maintain your Chocolatey installation"
    
    Write-Success "Chocolatey cleanup completed at $(Get-Date)"
}

# Run main function
Main 