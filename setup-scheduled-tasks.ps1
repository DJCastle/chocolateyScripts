#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Sets up Windows scheduled tasks for automated Chocolatey maintenance.

.DESCRIPTION
    Creates scheduled tasks to run auto-update and cleanup scripts automatically.
    Configures tasks based on user preferences with safe defaults.

.NOTES
    Requires Administrator privileges.
    Logs to: $env:USERPROFILE\Logs\ScheduledTaskSetup.log
#>

# Set up logging
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\ScheduledTaskSetup.log"
Add-Content -Path $LogFile -Value "Starting Scheduled Task Setup at $(Get-Date)"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Create scheduled task for auto-update
function New-AutoUpdateTask {
    param(
        [string]$Time = "03:00",
        [string[]]$Days = @("Sunday", "Wednesday")
    )

    Write-Status "Creating scheduled task for auto-update..."

    $taskName = "Chocolatey Auto-Update"
    $taskDescription = "Automatically updates Chocolatey and installed packages"

    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-LogWarning "Removing existing task: $taskName"
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    try {
        # Create action
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\auto-update-chocolatey.ps1`"" `
            -WorkingDirectory $ScriptDir

        # Create trigger(s)
        $triggers = @()
        foreach ($day in $Days) {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $Time
            $triggers += $trigger
        }

        # Create settings
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries:$false `
            -DontStopIfGoingOnBatteries:$false `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable `
            -ExecutionTimeLimit (New-TimeSpan -Hours 2)

        # Create principal (run as SYSTEM with highest privileges)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        # Register task
        Register-ScheduledTask -TaskName $taskName `
            -Description $taskDescription `
            -Action $action `
            -Trigger $triggers[0] `
            -Settings $settings `
            -Principal $principal | Out-Null

        # Add additional triggers if multiple days specified
        if ($triggers.Count -gt 1) {
            $task = Get-ScheduledTask -TaskName $taskName
            for ($i = 1; $i -lt $triggers.Count; $i++) {
                $task.Triggers += $triggers[$i]
            }
            $task | Set-ScheduledTask | Out-Null
        }

        Write-Success "Created scheduled task: $taskName"
        Write-Status "Schedule: $($Days -join ', ') at $Time"

        return $true
    }
    catch {
        Write-LogError "Failed to create scheduled task: $($_.Exception.Message)"
        return $false
    }
}

# Create scheduled task for cleanup
function New-CleanupTask {
    param(
        [string]$Frequency = "Monthly"
    )

    Write-Status "Creating scheduled task for cleanup..."

    $taskName = "Chocolatey Cleanup"
    $taskDescription = "Performs Chocolatey maintenance and cleanup"

    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-LogWarning "Removing existing task: $taskName"
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    try {
        # Create action
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\cleanup-chocolatey.ps1`"" `
            -WorkingDirectory $ScriptDir

        # Create trigger based on frequency
        switch ($Frequency) {
            "Daily" {
                $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
            }
            "Weekly" {
                $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "02:00"
            }
            "Monthly" {
                $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Sunday -At "02:00"
            }
            default {
                $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Sunday -At "02:00"
            }
        }

        # Create settings
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries:$false `
            -DontStopIfGoingOnBatteries:$false `
            -StartWhenAvailable `
            -ExecutionTimeLimit (New-TimeSpan -Hours 1)

        # Create principal (run as SYSTEM with highest privileges)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        # Register task
        Register-ScheduledTask -TaskName $taskName `
            -Description $taskDescription `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal | Out-Null

        Write-Success "Created scheduled task: $taskName"
        Write-Status "Schedule: $Frequency at 02:00"

        return $true
    }
    catch {
        Write-LogError "Failed to create scheduled task: $($_.Exception.Message)"
        return $false
    }
}

# List existing Chocolatey tasks
function Show-ExistingTasks {
    Write-Status "Checking for existing Chocolatey scheduled tasks..."

    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*Chocolatey*" }

    if ($tasks) {
        Write-Host ""
        Write-Host "Existing Chocolatey Scheduled Tasks:" -ForegroundColor Cyan
        Write-Host "=====================================" -ForegroundColor Cyan

        foreach ($task in $tasks) {
            $info = Get-ScheduledTaskInfo -TaskName $task.TaskName
            Write-Host ""
            Write-Host "Name: $($task.TaskName)" -ForegroundColor White
            Write-Host "State: $($task.State)" -ForegroundColor $(if ($task.State -eq "Ready") { "Green" } else { "Yellow" })
            Write-Host "Last Run: $($info.LastRunTime)"
            Write-Host "Next Run: $($info.NextRunTime)"
            Write-Host "Last Result: $($info.LastTaskResult)"
        }
        Write-Host ""
    }
    else {
        Write-LogWarning "No existing Chocolatey scheduled tasks found"
    }
}

# Remove all Chocolatey tasks
function Remove-AllChocolateyTasks {
    Write-Status "Removing all Chocolatey scheduled tasks..."

    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*Chocolatey*" }

    if ($tasks) {
        foreach ($task in $tasks) {
            try {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
                Write-Success "Removed task: $($task.TaskName)"
            }
            catch {
                Write-LogError "Failed to remove task $($task.TaskName): $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Status "No Chocolatey tasks to remove"
    }
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Chocolatey Scheduled Tasks Setup                          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Check if running as Administrator
    if (-not (Test-Administrator)) {
        Write-LogError "This script must be run as Administrator."
        Write-LogError "Please right-click PowerShell and select 'Run as Administrator'."
        exit 1
    }

    # Show existing tasks
    Show-ExistingTasks

    # Main menu
    Write-Host ""
    Write-Host "What would you like to do?" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Create Auto-Update task (recommended)"
    Write-Host "2. Create Cleanup task"
    Write-Host "3. Create both tasks"
    Write-Host "4. Remove all Chocolatey tasks"
    Write-Host "5. View existing tasks"
    Write-Host "6. Exit"
    Write-Host ""

    $choice = Read-Host "Enter your choice (1-6)"

    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "Auto-Update Task Configuration:" -ForegroundColor Cyan
            $time = Read-Host "Enter time to run (default: 03:00)"
            if ([string]::IsNullOrEmpty($time)) { $time = "03:00" }

            Write-Host "Select days (comma-separated: Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday)"
            $daysInput = Read-Host "Enter days (default: Sunday,Wednesday)"
            if ([string]::IsNullOrEmpty($daysInput)) {
                $days = @("Sunday", "Wednesday")
            }
            else {
                $days = $daysInput -split ',' | ForEach-Object { $_.Trim() }
            }

            New-AutoUpdateTask -Time $time -Days $days
        }
        "2" {
            Write-Host ""
            Write-Host "Cleanup Task Configuration:" -ForegroundColor Cyan
            Write-Host "Select frequency:"
            Write-Host "1. Daily"
            Write-Host "2. Weekly"
            Write-Host "3. Monthly (recommended)"
            $freqChoice = Read-Host "Enter choice (1-3, default: 3)"

            $frequency = switch ($freqChoice) {
                "1" { "Daily" }
                "2" { "Weekly" }
                default { "Monthly" }
            }

            New-CleanupTask -Frequency $frequency
        }
        "3" {
            Write-Success "Creating both tasks with default settings..."
            New-AutoUpdateTask -Time "03:00" -Days @("Sunday", "Wednesday")
            New-CleanupTask -Frequency "Monthly"
        }
        "4" {
            $confirm = Read-Host "Are you sure you want to remove all Chocolatey tasks? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") {
                Remove-AllChocolateyTasks
            }
            else {
                Write-Status "Operation cancelled"
            }
        }
        "5" {
            Show-ExistingTasks
        }
        "6" {
            Write-Status "Exiting..."
            exit 0
        }
        default {
            Write-LogWarning "Invalid choice"
            exit 1
        }
    }

    Write-Host ""
    Write-Success "Scheduled task setup completed at $(Get-Date)"
    Write-Host ""
    Write-Status "You can manage these tasks using:"
    Write-Status "- Task Scheduler (taskschd.msc)"
    Write-Status "- PowerShell: Get-ScheduledTask | Where-Object { `$_.TaskName -like '*Chocolatey*' }"
}

# Run main function
Main
