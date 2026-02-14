# Getting Started with Chocolatey Scripts

Welcome! This guide will walk you through setting up and using the Chocolatey Scripts automation suite on your Windows machine.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Configuration](#configuration)
4. [Running Scripts](#running-scripts)
5. [Automation Setup](#automation-setup)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)
8. [Next Steps](#next-steps)

## Prerequisites

### System Requirements

- **Operating System**: Windows 10 (1809+) or Windows 11
- **PowerShell**: Version 5.1 or later (PowerShell 7+ recommended)
- **Privileges**: Administrator rights for installation and updates
- **Internet**: Active internet connection
- **Disk Space**: At least 10 GB free space recommended

### Check Your PowerShell Version

```powershell
$PSVersionTable.PSVersion
```

If you have version 5.1, consider upgrading to PowerShell 7+ for better performance:

```powershell
# After installing Chocolatey, you can install PowerShell 7+
choco install powershell-core -y
```

## Initial Setup

### Step 1: Download the Scripts

Clone or download this repository to your local machine:

```powershell
# Using Git
git clone https://github.com/DJCastle/chocolateyScripts.git
cd chocolateyScripts

# Or download and extract the ZIP file from GitHub
```

### Step 2: Set Execution Policy

Open PowerShell as Administrator and allow script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 3: Install Chocolatey

Run the Chocolatey installation script:

```powershell
.\install-chocolatey.ps1
```

**What this does:**
- Downloads and installs Chocolatey package manager
- Configures environment variables
- Enables global confirmation (reduces prompts)
- Runs health checks with `choco doctor`
- Creates installation logs in `%USERPROFILE%\Logs\`

**Expected output:**
- Green success messages showing installation progress
- Chocolatey version information
- Configuration status

### Step 4: Install Essential Applications

Install a curated set of essential Windows applications:

```powershell
.\install-essential-apps.ps1
```

**Applications installed:**
- **Browsers**: Chrome, Firefox, Edge
- **Development**: VS Code, Notepad++, Git, PowerShell 7+
- **Utilities**: 7-Zip, VLC, Windows Terminal
- **Communication**: Discord
- **Gaming**: Steam

**Customization:**
Edit the `$apps` array in the script to add/remove applications.

### Step 5: Run Health Check

Verify everything is working correctly:

```powershell
.\health-check.ps1
```

**What it checks:**
- Chocolatey installation status
- System requirements
- Outdated packages
- Disk usage
- Configuration issues
- Scheduled tasks

## Configuration

### Customize config.json

First, copy the example config to create your personal configuration:

```powershell
Copy-Item config.example.json config.json
notepad config.json
```

The `config.json` file centralizes all script settings. Edit it to match your environment.

**Key settings to configure:**

#### Network Settings

```json
"wifiNetwork": "YourWiFiName",
```

Set this to your preferred WiFi network for auto-updates.

#### Email Notifications

```json
"emailAddress": "your-email@example.com",
"smtpServer": "smtp.gmail.com",
"smtpPort": 587,
```

Configure SMTP settings for email notifications.

**Note**: For Gmail, you'll need to use an [App Password](https://support.google.com/accounts/answer/185833).

#### Notification Preferences

```json
"notifications": {
  "enableEmailNotifications": false,
  "enableToastNotifications": true,
  "notifyOnSuccess": true,
  "notifyOnError": true,
  "notifyOnWarning": false
}
```

Enable/disable different types of notifications.

#### Backup Settings

```json
"backupSettings": {
  "backupPath": "%USERPROFILE%\\Documents\\ChocolateyBackups",
  "autoBackupBeforeUpdate": true,
  "keepBackups": 5
}
```

Configure automatic backups before updates.

### Create Initial Backup

Create a backup of your current package configuration:

```powershell
.\backup-packages.ps1 -Action Backup
```

Your backup will be saved to:
`%USERPROFILE%\Documents\ChocolateyBackups\chocolatey-backup-YYYY-MM-DD_HHMMSS.json`

## Running Scripts

### Manual Updates

Update all packages manually:

```powershell
.\auto-update-chocolatey.ps1
```

**Conditions checked:**
- Connected to specified WiFi network (configurable)
- Plugged into power (not on battery)
- Has administrator privileges

**What it does:**
1. Updates Chocolatey itself
2. Upgrades all installed packages
3. Runs cleanup to remove old versions
4. Sends notifications (if configured)
5. Logs all operations

### Manual Cleanup

Free up disk space:

```powershell
.\cleanup-chocolatey.ps1
```

**What it cleans:**
- Old package versions
- Cached package files
- Orphaned dependencies
- Temporary installation files

**Disk space savings:**
Typically saves 500MB - 2GB depending on usage.

### Health Monitoring

Run health checks periodically:

```powershell
.\health-check.ps1
```

**When to run:**
- After installing new packages
- When experiencing issues
- Monthly maintenance checks
- Before major updates

## Automation Setup

### Set Up Scheduled Tasks

Use the interactive wizard to automate maintenance:

```powershell
.\setup-scheduled-tasks.ps1
```

**Options available:**

1. **Auto-Update Task**
   - Choose days of the week (e.g., Sunday, Wednesday)
   - Set time (e.g., 3:00 AM)
   - Runs only when conditions are met (WiFi, power)

2. **Cleanup Task**
   - Daily, Weekly, or Monthly frequency
   - Runs during off-peak hours
   - Optimizes disk space automatically

3. **View/Manage Tasks**
   - See existing Chocolatey tasks
   - Check last run times
   - Remove unwanted tasks

### Recommended Schedule

For most users, we recommend:

- **Auto-Update**: Sunday and Wednesday at 3:00 AM
- **Cleanup**: Monthly (first Sunday of the month)

This ensures:
- Regular security updates
- Minimal disk space usage
- No interference with work hours

## Best Practices

### Security

1. **Review Scripts Before Running**
   ```powershell
   # Read any script before executing it
   Get-Content .\script-name.ps1 | more
   ```

2. **Keep Logs**
   - Logs are saved to `%USERPROFILE%\Logs\`
   - Review them periodically for issues
   - Keep for troubleshooting

3. **Regular Backups**
   ```powershell
   # Create monthly backups
   .\backup-packages.ps1 -Action Backup
   ```

4. **Verify Package Sources**
   ```powershell
   # Check package information before installing
   choco info package-name
   ```

### Performance

1. **Use PowerShell 7+**
   - Faster execution
   - Better error handling
   - Modern features

2. **Run Cleanup Monthly**
   - Prevents disk space issues
   - Removes outdated packages
   - Improves performance

3. **Schedule During Off-Peak Hours**
   - Less network congestion
   - Doesn't interfere with work
   - Better download speeds

### Maintenance

1. **Monthly Tasks**
   - Run health check
   - Review logs for errors
   - Create package backup
   - Run cleanup script

2. **Quarterly Tasks**
   - Review installed packages (remove unused)
   - Update documentation
   - Check for script updates

3. **Yearly Tasks**
   - Export package list for records
   - Review automation schedules
   - Update configuration settings

## Troubleshooting

### Common Issues

#### 1. "Execution Policy" Error

**Problem**: PowerShell blocks script execution

**Solution**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. "Chocolatey Not Found"

**Problem**: Command not recognized after installation

**Solution**:
```powershell
# Refresh environment variables
refreshenv

# Or restart PowerShell
```

#### 3. Script Requires Administrator

**Problem**: Access denied errors

**Solution**:
1. Right-click PowerShell
2. Select "Run as Administrator"
3. Re-run the script

#### 4. Package Installation Fails

**Problem**: Individual package won't install

**Solution**:
```powershell
# Try installing with verbose output
choco install package-name -y -v

# Check package exists
choco search package-name

# View logs
Get-Content "$env:USERPROFILE\Logs\*.log" | Select-String "ERROR"
```

#### 5. WiFi Network Not Detected

**Problem**: Auto-update skips because WiFi not detected

**Solution**:
1. Verify WiFi network name in config.json matches exactly
2. Check network adapter name:
   ```powershell
   Get-NetAdapter | Where-Object Status -eq "Up"
   ```
3. Update WiFi detection in auto-update script if needed

#### 6. Low Disk Space Warnings

**Problem**: Running out of disk space

**Solution**:
```powershell
# Run cleanup immediately
.\cleanup-chocolatey.ps1

# Check disk usage
.\health-check.ps1

# Remove unused packages
choco uninstall package-name -y
```

### Getting Help

1. **Check Logs**
   ```powershell
   # View recent errors
   Get-Content "$env:USERPROFILE\Logs\*.log" | Select-String "ERROR" | Select-Object -Last 20
   ```

2. **Run Health Check**
   ```powershell
   .\health-check.ps1
   ```

3. **Chocolatey Doctor**
   ```powershell
   choco doctor
   ```

4. **Community Support**
   - GitHub Issues: https://github.com/DJCastle/chocolateyScripts/issues
   - Chocolatey Documentation: https://docs.chocolatey.org/

## Next Steps

### For Basic Users

1. ✅ Install Chocolatey and essential apps
2. ✅ Create initial backup
3. ✅ Set up auto-update scheduled task
4. ✅ Run monthly health checks

### For Advanced Users

1. ✅ Customize package list in install-essential-apps.ps1
2. ✅ Configure email notifications
3. ✅ Set up multiple backup locations
4. ✅ Create custom package lists for different machines
5. ✅ Integrate with monitoring systems
6. ✅ Automate backup rotation

### Recommended Workflow

```powershell
# Weekly: Check for updates manually (or let scheduled task run)
.\auto-update-chocolatey.ps1

# Monthly: Run health check and cleanup
.\health-check.ps1
.\cleanup-chocolatey.ps1

# Monthly: Create backup
.\backup-packages.ps1 -Action Backup

# As needed: Install new packages
choco install package-name -y
```

### Create a .gitignore (Optional)

If you plan to track your own changes with git, create a `.gitignore` to protect your personal config:

```gitignore
config.json
config.local.json
smtp-credential.xml
.env
*.log
```

This prevents accidentally committing your WiFi name, email, or SMTP credentials.

## Additional Resources

- **[powershell-scripting-tutorial.md](powershell-scripting-tutorial.md)** - PowerShell scripting tutorial with examples from this project
- **[safety-and-best-practices.md](safety-and-best-practices.md)** - Safety guide and best practices for these scripts
- **Chocolatey Documentation**: https://docs.chocolatey.org/
- **PowerShell Documentation**: https://docs.microsoft.com/powershell/
- **Package Search**: https://community.chocolatey.org/packages
- **This Project**: https://github.com/DJCastle/chocolateyScripts

## Contributing

Found a bug or have a suggestion? Please:

1. Check existing issues on GitHub
2. Create a new issue with details
3. Submit a pull request with improvements

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

**Happy Automating! 🍫**

If you find these scripts useful, please consider starring the repository on GitHub!
