#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
    Backs up or restores Chocolatey package list.

.DESCRIPTION
    Exports currently installed Chocolatey packages to a file, or restores packages from a backup.
    Useful for migrating to a new machine or recovering after system issues.

.PARAMETER Action
    Action to perform: Backup or Restore

.PARAMETER BackupFile
    Path to the backup file (defaults to timestamped file in Documents)

.NOTES
    Safe to run multiple times.
    Logs to: $env:USERPROFILE\Logs\ChocolateyBackup.log
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Backup", "Restore", "List")]
    [string]$Action = "Backup",

    [Parameter(Mandatory=$false)]
    [string]$BackupFile = ""
)

# Set up logging
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\ChocolateyBackup.log"
Add-Content -Path $LogFile -Value "Starting Chocolatey Backup at $(Get-Date)"

# Default backup location
$DefaultBackupPath = "$env:USERPROFILE\Documents\ChocolateyBackups"
if (-not (Test-Path $DefaultBackupPath)) {
    New-Item -ItemType Directory -Path $DefaultBackupPath -Force | Out-Null
}

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

# Backup packages
function Backup-Packages {
    param([string]$OutputFile)

    Write-Status "Backing up Chocolatey packages..."

    try {
        # Get list of installed packages
        $packages = choco list --limit-output

        if ($packages) {
            # Parse package information
            $packageList = @()
            foreach ($pkg in $packages) {
                $parts = $pkg -split '\|'
                if ($parts.Count -ge 2) {
                    $packageList += @{
                        Name = $parts[0]
                        Version = $parts[1]
                    }
                }
            }

            # Create backup object
            $backup = @{
                BackupDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ComputerName = $env:COMPUTERNAME
                ChocolateyVersion = (choco --version)
                PackageCount = $packageList.Count
                Packages = $packageList
            }

            # Save to JSON file
            $backup | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8

            Write-Success "Backed up $($packageList.Count) packages to: $OutputFile"
            Write-Status "Backup includes package names and versions"

            return $true
        }
        else {
            Write-LogWarning "No packages found to backup"
            return $false
        }
    }
    catch {
        Write-LogError "Failed to backup packages: $($_.Exception.Message)"
        return $false
    }
}

# Restore packages
function Restore-Packages {
    param([string]$InputFile)

    Write-Status "Restoring Chocolatey packages from backup..."

    if (-not (Test-Path $InputFile)) {
        Write-LogError "Backup file not found: $InputFile"
        return $false
    }

    try {
        # Read backup file
        $backup = Get-Content $InputFile -Raw | ConvertFrom-Json

        Write-Status "Backup Information:"
        Write-Host "  Date: $($backup.BackupDate)"
        Write-Host "  Computer: $($backup.ComputerName)"
        Write-Host "  Packages: $($backup.PackageCount)"
        Write-Host ""

        # Confirm restore
        $confirm = Read-Host "Do you want to restore these packages? (Y/N)"
        if ($confirm -ne "Y" -and $confirm -ne "y") {
            Write-LogWarning "Restore cancelled by user"
            return $false
        }

        # Install packages
        $successCount = 0
        $failCount = 0
        $skippedCount = 0

        foreach ($pkg in $backup.Packages) {
            Write-Status "Processing: $($pkg.Name) v$($pkg.Version)"

            # Check if already installed
            $installed = choco list $pkg.Name --limit-output
            if ($installed -match $pkg.Name) {
                Write-LogWarning "$($pkg.Name) is already installed - skipping"
                $skippedCount++
                continue
            }

            # Install package
            try {
                choco install $pkg.Name --version=$($pkg.Version) -y | Tee-Object -FilePath $LogFile -Append
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Installed: $($pkg.Name)"
                    $successCount++
                }
                else {
                    Write-LogError "Failed to install: $($pkg.Name)"
                    $failCount++
                }
            }
            catch {
                Write-LogError "Error installing $($pkg.Name): $($_.Exception.Message)"
                $failCount++
            }
        }

        # Summary
        Write-Host ""
        Write-Status "Restore Summary:"
        Write-Success "Successfully installed: $successCount packages"
        Write-LogWarning "Skipped (already installed): $skippedCount packages"
        Write-LogError "Failed: $failCount packages"

        return $true
    }
    catch {
        Write-LogError "Failed to restore packages: $($_.Exception.Message)"
        return $false
    }
}

# List available backups
function List-Backups {
    Write-Status "Available backups in: $DefaultBackupPath"

    $backups = Get-ChildItem -Path $DefaultBackupPath -Filter "chocolatey-backup-*.json" -ErrorAction SilentlyContinue

    if ($backups) {
        Write-Host ""
        Write-Host "Found $($backups.Count) backup(s):"
        Write-Host ""

        foreach ($backup in $backups | Sort-Object LastWriteTime -Descending) {
            try {
                $content = Get-Content $backup.FullName -Raw | ConvertFrom-Json
                Write-Host "  File: $($backup.Name)"
                Write-Host "  Date: $($content.BackupDate)"
                Write-Host "  Computer: $($content.ComputerName)"
                Write-Host "  Packages: $($content.PackageCount)"
                Write-Host "  Size: $([math]::Round($backup.Length / 1KB, 2)) KB"
                Write-Host ""
            }
            catch {
                Write-LogWarning "Could not read backup: $($backup.Name)"
            }
        }
    }
    else {
        Write-LogWarning "No backups found in $DefaultBackupPath"
    }
}

# Main execution
function Main {
    Write-Status "Chocolatey Backup/Restore started at $(Get-Date)"

    # Check if Chocolatey is installed
    if (-not (Test-ChocolateyInstalled)) {
        Write-LogError "Chocolatey is not installed. Please run .\install-chocolatey.ps1 first."
        exit 1
    }

    # Determine backup file path
    if ([string]::IsNullOrEmpty($BackupFile)) {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $BackupFile = "$DefaultBackupPath\chocolatey-backup-$timestamp.json"
    }

    # Perform action
    switch ($Action) {
        "Backup" {
            if (Backup-Packages -OutputFile $BackupFile) {
                Write-Success "Backup completed successfully"
                Write-Status "You can restore this backup using: .\backup-packages.ps1 -Action Restore -BackupFile '$BackupFile'"
            }
            else {
                Write-LogError "Backup failed"
                exit 1
            }
        }
        "Restore" {
            if ([string]::IsNullOrEmpty($BackupFile) -or $BackupFile -match "chocolatey-backup-\d{4}-\d{2}-\d{2}_\d{6}\.json$") {
                # User didn't specify a file, show available backups
                List-Backups
                Write-Host ""
                $BackupFile = Read-Host "Enter the full path to the backup file you want to restore"
            }

            if (Restore-Packages -InputFile $BackupFile) {
                Write-Success "Restore completed"
            }
            else {
                Write-LogError "Restore failed"
                exit 1
            }
        }
        "List" {
            List-Backups
        }
    }

    Write-Success "Operation completed at $(Get-Date)"
}

# Run main function
Main
