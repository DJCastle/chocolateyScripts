# Safety and Best Practices Guide

This guide explains the safety measures built into these scripts and provides best practices for using and modifying Windows automation scripts.

## Critical Safety Information

### Before You Begin

**Please read this section completely before running any scripts.**

These scripts will modify your system. While they include safety measures, you should understand the risks and take appropriate precautions.

### What These Scripts Do

1. **Install Software** — Chocolatey package manager and Windows applications
2. **Modify System Settings** — Execution policy, environment variables
3. **Create Scheduled Tasks** — Automatic update and maintenance jobs
4. **Network Operations** — Download packages and updates from the internet
5. **File System Changes** — Create directories, log files, and configuration files

### Potential Risks

- **System Changes** — May affect how applications and services behave
- **Network Usage** — Downloads can consume bandwidth and data
- **Disk Space** — Applications and caches require storage
- **Security** — Installing software always carries some security risk
- **Admin Privileges** — Most operations require elevated PowerShell

## Built-in Safety Measures

### 1. Idempotent Operations
```powershell
# Safe to run multiple times - checks before acting
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Success "Chocolatey is already installed"
    return
}
```

**Benefits:**
- Running scripts multiple times won't cause problems
- Can resume safely after interruptions
- Won't duplicate installations
- Detects existing state before making changes

### 2. Prerequisite Checks
```powershell
# Validates your system before making any changes
.\validate-setup.ps1
```

**What it checks:**
- PowerShell version meets requirements
- Administrator privileges are available
- Chocolatey is installed and working
- Config file exists and has valid syntax
- Disk space is sufficient
- Network connectivity works

### 3. Comprehensive Logging
```powershell
# All operations are logged with timestamps
$LogFile = "$env:USERPROFILE\Logs\ChocolateyInstall.log"

# Example log entries
[2026-02-06 14:30:15] [INFO] Installing Visual Studio Code...
[2026-02-06 14:30:45] [SUCCESS] Visual Studio Code installed successfully
```

**What's logged:**
- Every operation performed
- All errors and warnings
- System state checks
- Timestamps for troubleshooting

### 4. Input Validation
```powershell
# Configuration files are validated before use
$config = Get-Content $configPath -Raw | ConvertFrom-Json
```

**Protections:**
- Config files are checked for valid JSON syntax
- System requirements are verified before proceeding
- Network and power conditions are checked before updates

### 5. Error Recovery
```powershell
# Automatic retry for transient failures
while ($retryCount -lt $MaxRetries) {
    try {
        # attempt the operation
    }
    catch {
        Write-Warning "Attempt $retryCount failed, retrying..."
        Start-Sleep -Seconds $RetryDelay
    }
    $retryCount++
}
```

**Features:**
- Automatic retry for network timeouts
- Graceful handling when operations fail
- Clear error messages with context

## Pre-Installation Checklist

### System Requirements
- [ ] Windows 10 or later (Windows 11 recommended)
- [ ] PowerShell 5.1 or later (PowerShell 7+ recommended)
- [ ] Administrator privileges (you know your password)
- [ ] At least 1 GB free disk space
- [ ] Stable internet connection

### Preparation Steps
- [ ] **Close important applications** to avoid conflicts
- [ ] **Review config.example.json** to understand what will be configured
- [ ] **Copy config.example.json to config.json** and customize it
- [ ] **Run validate-setup.ps1** to check your environment
- [ ] **Have your password ready** for administrator prompts

### Network Considerations
- [ ] Connected to a reliable network
- [ ] Sufficient bandwidth for downloads
- [ ] Not on a metered connection (if data usage is a concern)
- [ ] Firewall allows Chocolatey downloads (chocolatey.org)

## Best Practices for Usage

### 1. Start with Validation
```powershell
# Always run the health check first
.\validate-setup.ps1
.\health-check.ps1
```

### 2. Install Chocolatey First
```powershell
# Step 1: Install the package manager
.\install-chocolatey.ps1

# Step 2: Then install apps
.\install-essential-apps.ps1
```

### 3. Review Logs When Something Fails
```powershell
# Check recent log entries
Get-Content "$env:USERPROFILE\Logs\ChocolateyInstall.log" -Tail 20

# Search for errors across all logs
Get-ChildItem "$env:USERPROFILE\Logs\Chocolatey*.log" |
    ForEach-Object { Select-String "ERROR" $_ }
```

### 4. Back Up Before Major Changes
```powershell
# Export your current package list
.\backup-packages.ps1 -Action Backup

# Restore on a new machine or after a problem
.\backup-packages.ps1 -Action Restore -BackupFile "path\to\backup.json"
```

### 5. Keep Configuration Under Version Control
Your `config.json` is git-ignored (it contains personal settings like your WiFi name). Keep a backup somewhere safe in case you need to set up again.

## Emergency Procedures

### If Something Goes Wrong

1. **Don't panic** — most issues are recoverable
2. **Check the logs** — `$env:USERPROFILE\Logs\`
3. **Stop the script** — press `Ctrl+C` if it's still running
4. **Note what happened** — which script, what step, what error

### Common Recovery Steps

#### Chocolatey Won't Install
```powershell
# Check execution policy
Get-ExecutionPolicy
# If "Restricted", fix it:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### A Package Won't Install
```powershell
# Remove a problem package
choco uninstall problematic-package -y

# Clear Chocolatey's download cache
Remove-Item "$env:TEMP\chocolatey" -Recurse -Force -ErrorAction SilentlyContinue
```

#### Scheduled Task Not Running
```powershell
# Check if the task exists
Get-ScheduledTask | Where-Object { $_.TaskName -like "*Chocolatey*" }

# Re-create it
.\setup-scheduled-tasks.ps1
```

### When to Seek Help

- **System won't boot** — Contact Microsoft Support or a technician
- **Applications won't start** — Check the app's own support resources
- **Permission errors** — Verify you're running as Administrator
- **Network issues** — Check your internet connection and firewall

## Security Considerations

### Script Security
- **Read before running** — Understand what a script does before executing it
- **Trusted sources only** — Only run scripts from sources you trust
- **Admin awareness** — Know that elevated scripts can change anything on your system
- **Keep scripts updated** — Pull the latest version for security fixes

### Application Security
- **Official sources** — Chocolatey packages come from the community repository
- **Checksum verification** — Chocolatey verifies package integrity
- **Keep apps updated** — Run `choco upgrade all` regularly for security patches

### Network Security
- **HTTPS** — Chocolatey uses encrypted connections for downloads
- **No credential storage** — These scripts don't store passwords (email config is optional)
- **Logged activity** — All network operations are recorded in log files

## Customization Guidelines

### Safe Modifications
- **config.json** — WiFi name, email, backup paths, scheduling preferences
- **install-essential-apps.ps1** — Add or remove apps from the installation list
- **Scheduled task timing** — Change when automatic updates run

### Testing Your Changes
```powershell
# Check PowerShell syntax without running
powershell -Command "& { Get-Content .\your-script.ps1 | Out-Null }"

# Use PSScriptAnalyzer for best practice checks
Invoke-ScriptAnalyzer -Path .\your-script.ps1
```

## Additional Resources

- [Chocolatey Documentation](https://docs.chocolatey.org/)
- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [Windows Security Guide](https://learn.microsoft.com/en-us/windows/security/)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)

**When in doubt, don't run it.** It's always better to understand what a script does before executing it on your system.
