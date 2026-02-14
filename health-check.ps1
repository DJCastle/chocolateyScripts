#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
    Performs comprehensive health check and diagnostics for Chocolatey.

.DESCRIPTION
    Checks Chocolatey installation, configuration, outdated packages, disk usage,
    and system requirements. Provides detailed report and recommendations.

.NOTES
    Safe to run without administrator privileges (some checks require admin).
    Logs to: $env:USERPROFILE\Logs\ChocolateyHealthCheck.log
#>

# Set up logging
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\ChocolateyHealthCheck.log"
Add-Content -Path $LogFile -Value "Starting Chocolatey Health Check at $(Get-Date)"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Blue
    Add-Content -Path $LogFile -Value "[INFO] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor $Green
    Add-Content -Path $LogFile -Value "[SUCCESS] $Message"
}

function Write-LogWarning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor $Yellow
    Add-Content -Path $LogFile -Value "[WARNING] $Message"
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor $Red
    Add-Content -Path $LogFile -Value "[ERROR] $Message"
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Cyan
    Write-Host " $Title" -ForegroundColor $Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Cyan
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check Chocolatey installation
function Test-ChocolateyInstallation {
    Write-Section "Chocolatey Installation"

    $issues = @()

    # Check if choco command exists
    try {
        $chocoCmd = Get-Command choco -ErrorAction Stop
        Write-Success "Chocolatey command found at: $($chocoCmd.Source)"

        # Get version
        $version = choco --version
        Write-Success "Chocolatey version: $version"

        # Check if version is outdated
        try {
            $latestVersion = (choco info chocolatey --limit-output) -split '\|' | Select-Object -Skip 1 -First 1
            if ($version -ne $latestVersion) {
                Write-LogWarning "Chocolatey is outdated. Latest version: $latestVersion"
                $issues += "Chocolatey is outdated"
            }
        }
        catch {
            Write-LogWarning "Could not check for latest Chocolatey version"
        }
    }
    catch {
        Write-LogError "Chocolatey is not installed or not in PATH"
        $issues += "Chocolatey not found"
        return $issues
    }

    # Check environment variables
    if ($env:ChocolateyInstall) {
        Write-Success "ChocolateyInstall environment variable set: $env:ChocolateyInstall"

        if (Test-Path $env:ChocolateyInstall) {
            Write-Success "Chocolatey directory exists"
        }
        else {
            Write-LogError "Chocolatey directory not found at: $env:ChocolateyInstall"
            $issues += "Chocolatey directory missing"
        }
    }
    else {
        Write-LogWarning "ChocolateyInstall environment variable not set"
        $issues += "Environment variable missing"
    }

    return $issues
}

# Check system requirements
function Test-SystemRequirements {
    Write-Section "System Requirements"

    $issues = @()

    # PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Status "PowerShell version: $psVersion"

    if ($psVersion.Major -ge 7) {
        Write-Success "Using PowerShell 7+ (recommended)"
    }
    elseif ($psVersion.Major -ge 5) {
        Write-LogWarning "Using PowerShell 5.x (consider upgrading to PowerShell 7+)"
        $issues += "PowerShell version could be upgraded"
    }
    else {
        Write-LogError "PowerShell version too old (minimum 5.1 required)"
        $issues += "PowerShell version too old"
    }

    # Windows version
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        Write-Status "OS: $($osInfo.Caption) (Build $($osInfo.BuildNumber))"

        if ($osInfo.BuildNumber -ge 22000) {
            Write-Success "Running Windows 11"
        }
        elseif ($osInfo.BuildNumber -ge 10240) {
            Write-Success "Running Windows 10"
        }
        else {
            Write-LogWarning "Windows version may not be fully supported"
            $issues += "Old Windows version"
        }
    }
    catch {
        Write-LogWarning "Could not determine Windows version"
    }

    # Administrator privileges
    if (Test-Administrator) {
        Write-Success "Running with administrator privileges"
    }
    else {
        Write-LogWarning "Not running as administrator (some operations may be limited)"
    }

    # Disk space
    try {
        $systemDrive = $env:SystemDrive
        $drive = Get-PSDrive $systemDrive.TrimEnd(':')
        $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)

        Write-Status "Free disk space on $systemDrive : $freeSpaceGB GB"

        if ($freeSpaceGB -lt 5) {
            Write-LogError "Low disk space (less than 5 GB free)"
            $issues += "Low disk space"
        }
        elseif ($freeSpaceGB -lt 10) {
            Write-LogWarning "Disk space getting low (less than 10 GB free)"
            $issues += "Disk space warning"
        }
        else {
            Write-Success "Sufficient disk space available"
        }
    }
    catch {
        Write-LogWarning "Could not check disk space"
    }

    # Internet connectivity
    try {
        $testConnection = Test-Connection -ComputerName "chocolatey.org" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($testConnection) {
            Write-Success "Internet connectivity verified"
        }
        else {
            Write-LogWarning "Could not reach chocolatey.org"
            $issues += "Network connectivity issue"
        }
    }
    catch {
        Write-LogWarning "Could not test internet connectivity"
    }

    return $issues
}

# Check installed packages
function Test-InstalledPackages {
    Write-Section "Installed Packages"

    $issues = @()

    try {
        # Get all installed packages
        $packages = choco list --limit-output

        if ($packages) {
            $packageCount = ($packages | Measure-Object).Count
            Write-Success "Total packages installed: $packageCount"

            # Check for outdated packages
            Write-Status "Checking for outdated packages..."
            $outdated = choco outdated --limit-output

            if ($outdated) {
                $outdatedCount = ($outdated | Measure-Object).Count
                Write-LogWarning "$outdatedCount package(s) have updates available:"

                foreach ($pkg in $outdated | Select-Object -First 10) {
                    $parts = $pkg -split '\|'
                    if ($parts.Count -ge 3) {
                        Write-Host "  - $($parts[0]): $($parts[1]) → $($parts[2])" -ForegroundColor Yellow
                    }
                }

                if ($outdatedCount -gt 10) {
                    Write-Host "  ... and $($outdatedCount - 10) more" -ForegroundColor Yellow
                }

                $issues += "$outdatedCount outdated packages"
            }
            else {
                Write-Success "All packages are up to date"
            }
        }
        else {
            Write-LogWarning "No packages installed"
        }
    }
    catch {
        Write-LogError "Failed to check installed packages: $($_.Exception.Message)"
        $issues += "Package check failed"
    }

    return $issues
}

# Check Chocolatey configuration
function Test-ChocolateyConfiguration {
    Write-Section "Chocolatey Configuration"

    $issues = @()

    try {
        # Check important configuration settings
        $config = choco config list

        # Check for global confirmation
        if ($config -match "allowGlobalConfirmation.*true") {
            Write-Success "Global confirmation is enabled"
        }
        else {
            Write-LogWarning "Global confirmation is disabled (may require manual confirmations)"
        }

        # Run choco doctor (requires Chocolatey Licensed Extension)
        Write-Status "Running Chocolatey doctor..."
        try {
            $doctorOutput = choco doctor 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Chocolatey doctor check passed"
            }
            else {
                Write-Status "choco doctor not available (requires Licensed Extension) — skipping"
            }
        }
        catch {
            Write-Status "choco doctor not available — skipping"
        }
    }
    catch {
        Write-LogError "Failed to check configuration: $($_.Exception.Message)"
        $issues += "Configuration check failed"
    }

    return $issues
}

# Check disk usage
function Test-DiskUsage {
    Write-Section "Disk Usage"

    $issues = @()

    try {
        if ($env:ChocolateyInstall) {
            $chocoPath = $env:ChocolateyInstall

            if (Test-Path $chocoPath) {
                $totalSize = (Get-ChildItem $chocoPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $totalSizeMB = [math]::Round($totalSize / 1MB, 2)

                Write-Status "Chocolatey installation size: $totalSizeMB MB"

                # Check lib folder size
                $libPath = "$chocoPath\lib"
                if (Test-Path $libPath) {
                    $libSize = (Get-ChildItem $libPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    $libSizeMB = [math]::Round($libSize / 1MB, 2)
                    Write-Status "Package library size: $libSizeMB MB"
                }

                if ($totalSizeMB -gt 5000) {
                    Write-LogWarning "Chocolatey installation is large (over 5 GB)"
                    Write-Status "Consider running cleanup-chocolatey.ps1"
                    $issues += "Large installation size"
                }
                else {
                    Write-Success "Chocolatey disk usage is reasonable"
                }
            }
        }
    }
    catch {
        Write-LogWarning "Could not calculate disk usage: $($_.Exception.Message)"
    }

    return $issues
}

# Check scheduled tasks
function Test-ScheduledTasks {
    Write-Section "Scheduled Tasks"

    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "*Chocolatey*" }

    if ($tasks) {
        Write-Success "Found $($tasks.Count) Chocolatey scheduled task(s):"

        foreach ($task in $tasks) {
            $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue
            Write-Host "  - $($task.TaskName): $($task.State)" -ForegroundColor $(if ($task.State -eq "Ready") { "Green" } else { "Yellow" })

            if ($info) {
                Write-Host "    Last run: $($info.LastRunTime)" -ForegroundColor Gray
                Write-Host "    Next run: $($info.NextRunTime)" -ForegroundColor Gray
            }
        }
    }
    else {
        Write-LogWarning "No Chocolatey scheduled tasks configured"
        Write-Status "Consider running setup-scheduled-tasks.ps1 for automation"
    }

    return @()
}

# Generate summary report
function Show-Summary {
    param(
        [array]$AllIssues
    )

    Write-Section "Health Check Summary"

    if ($AllIssues.Count -eq 0) {
        Write-Host ""
        Write-Success "╔════════════════════════════════════════════════╗"
        Write-Success "║  All checks passed! Chocolatey is healthy.    ║"
        Write-Success "╚════════════════════════════════════════════════╝"
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-LogWarning "╔════════════════════════════════════════════════╗"
        Write-LogWarning "║  Found $($AllIssues.Count) issue(s) that need attention:        ║"
        Write-LogWarning "╚════════════════════════════════════════════════╝"
        Write-Host ""

        foreach ($issue in $AllIssues) {
            Write-Host "  • $issue" -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Status "Recommendations:"

        if ($AllIssues -match "outdated") {
            Write-Host "  → Run: .\auto-update-chocolatey.ps1" -ForegroundColor Cyan
        }

        if ($AllIssues -match "disk space|Large installation") {
            Write-Host "  → Run: .\cleanup-chocolatey.ps1" -ForegroundColor Cyan
        }

        if ($AllIssues -match "PowerShell version") {
            Write-Host "  → Install PowerShell 7+: choco install powershell-core -y" -ForegroundColor Cyan
        }

        if ($AllIssues -match "Doctor check failed") {
            Write-Host "  → Review: choco doctor" -ForegroundColor Cyan
        }

        Write-Host ""
    }
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
    Write-Host "║     Chocolatey Health Check & Diagnostics Tool             ║" -ForegroundColor $Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan

    $allIssues = @()

    # Run all checks
    $allIssues += Test-ChocolateyInstallation
    $allIssues += Test-SystemRequirements
    $allIssues += Test-InstalledPackages
    $allIssues += Test-ChocolateyConfiguration
    $allIssues += Test-DiskUsage
    $allIssues += Test-ScheduledTasks

    # Show summary
    Show-Summary -AllIssues $allIssues

    Write-Status "Health check completed at $(Get-Date)"
    Write-Status "Full log available at: $LogFile"
    Write-Host ""

    # Return exit code based on issues
    if ($allIssues.Count -eq 0) {
        exit 0
    }
    else {
        exit 1
    }
}

# Run main function
Main
