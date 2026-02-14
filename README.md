# Chocolatey Scripts

PowerShell scripts for managing Chocolatey package manager on Windows systems.

> **New to this project?** Check out [GETTING_STARTED.md](GETTING_STARTED.md) for a comprehensive setup guide!

## Quick Start

### Basic Setup

```powershell
# 0. Validate your setup
.\validate-setup.ps1

# 1. Install Chocolatey
.\install-chocolatey.ps1

# 2. Install essential applications
.\install-essential-apps.ps1

# 3. Run health check
.\health-check.ps1
```

### Advanced Setup (Recommended)

```powershell
# 4. Create your config and customize it
Copy-Item config.example.json config.json
notepad config.json

# 5. Setup automated maintenance
.\setup-scheduled-tasks.ps1

# 6. Create initial backup
.\backup-packages.ps1 -Action Backup
```

### Maintenance

```powershell
# Update packages
.\auto-update-chocolatey.ps1

# Clean up old packages
.\cleanup-chocolatey.ps1

# Check system health
.\health-check.ps1
```

## Scripts

### Core Scripts

| Script | Description |
| ------ | ----------- |
| `install-chocolatey.ps1` | Installs Chocolatey package manager |
| `install-essential-apps.ps1` | Installs essential Windows applications |
| `auto-update-chocolatey.ps1` | Updates Chocolatey and packages with conditions |
| `cleanup-chocolatey.ps1` | Cleans up old package versions and cache |

### Advanced Scripts (New for 2026!)

| Script | Description |
| ------ | ----------- |
| `health-check.ps1` | Comprehensive diagnostics and health check |
| `backup-packages.ps1` | Backup/restore package lists for migration |
| `setup-scheduled-tasks.ps1` | Automate updates with Windows Task Scheduler |
| `Send-ToastNotification.ps1` | Modern Windows Toast notification helper |
| `validate-setup.ps1` | Validate installation and configuration |

### Configuration & Documentation

| File | Description |
| ---- | ----------- |
| `config.example.json` | Configuration template — copy to `config.json` and customize |
| `GETTING_STARTED.md` | Comprehensive setup and usage guide |
| `CHANGELOG.md` | Version history and release notes |

## Requirements

- Windows 10/11 (Windows 11 recommended)
- PowerShell 5.1+ (PowerShell 7+ recommended for best performance)
- Administrator privileges
- Internet connection

## Essential Applications

The `install-essential-apps.ps1` script installs:

- **Browsers**: Chrome, Firefox, Edge
- **Development**: VS Code, Notepad++, Git, PowerShell 7+
- **Utilities**: 7-Zip, VLC, Windows Terminal
- **Communication**: Discord
- **Gaming**: Steam

## Advanced Features

### Health Check & Diagnostics

Run comprehensive system diagnostics:

```powershell
.\health-check.ps1
```

Checks:

- Chocolatey installation and version
- System requirements and disk space
- Outdated packages
- Configuration issues
- Scheduled tasks status

### Package Backup & Restore

Backup your installed packages:

```powershell
# Create backup
.\backup-packages.ps1 -Action Backup

# Restore from backup
.\backup-packages.ps1 -Action Restore -BackupFile "path\to\backup.json"

# List available backups
.\backup-packages.ps1 -Action List
```

Perfect for:

- Migrating to a new machine
- Disaster recovery
- Testing package combinations

### Automated Scheduling

Set up automatic maintenance:

```powershell
# Interactive setup wizard
.\setup-scheduled-tasks.ps1
```

Creates Windows scheduled tasks for:

- Auto-updates (customizable days/times)
- Cleanup maintenance (daily/weekly/monthly)

## Script Configuration

### Auto-Update Conditions

The `auto-update-chocolatey.ps1` script runs when:

- Connected to your configured WiFi network
- Plugged into power (not on battery)
- Has administrator privileges

Settings are loaded from `config.json`. Copy the example and customize:

```powershell
Copy-Item config.example.json config.json
notepad config.json
```

## Logging

All scripts log to `%USERPROFILE%\Logs\`:

- `ChocolateyInstall.log`
- `EssentialAppsInstall.log`
- `AutoUpdateChocolatey.log`
- `ChocolateyCleanup.log`

## Security Best Practices

- Always review scripts before running them with administrator privileges
- Keep Chocolatey and packages updated regularly using `auto-update-chocolatey.ps1`
- Only install packages from trusted sources
- Review package installation logs for any suspicious activity
- Use `choco info <package>` to verify package details before installation

## Troubleshooting

### Common Issues

**Execution Policy Error:**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Administrator Rights:**

Right-click PowerShell and select "Run as Administrator"

**Chocolatey Not Found:**

```powershell
refreshenv  # Or restart PowerShell
```

### View Logs

```powershell
# View recent log entries
Get-Content "$env:USERPROFILE\Logs\ChocolateyInstall.log" -Tail 20

# Search for errors
Get-Content "$env:USERPROFILE\Logs\*.log" | Select-String "ERROR"
```

## What's New in 2026 🎉

This project has been completely refreshed for 2026 with major enhancements:

### New Scripts

- **health-check.ps1** - Comprehensive diagnostics and health monitoring
- **backup-packages.ps1** - Package backup/restore for easy migration
- **setup-scheduled-tasks.ps1** - Interactive task scheduler setup wizard
- **Send-ToastNotification.ps1** - Modern Windows Toast notifications

### New Features

- **Centralized Configuration** - Single `config.json` for all settings
- **Enhanced Package List** - Added PowerShell 7+ and Git to essentials
- **Improved Error Handling** - Better retry logic and network detection
- **Modern APIs** - Using CIM cmdlets instead of deprecated WMI
- **Better WiFi Detection** - Improved network adapter detection

### Bug Fixes

- Fixed critical PowerShell syntax error in install-chocolatey.ps1
- Improved power status detection for modern Windows systems
- Better SSID regex pattern matching
- Enhanced battery status checks

### Infrastructure Updates

- Updated to Node.js 22 in GitHub Actions
- Updated copyright to 2026
- Improved markdown documentation formatting
- Enhanced security best practices section

## Performance Tips

- Use PowerShell 7+ for better performance and modern features
- Run cleanup script monthly to free up disk space
- Schedule auto-update during off-peak hours
- Consider using SSD for better package installation speed

## Documentation

- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Comprehensive setup guide for new users
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and detailed release notes
- **[powershell-scripting-tutorial.md](powershell-scripting-tutorial.md)** - PowerShell scripting tutorial with real examples
- **[safety-and-best-practices.md](safety-and-best-practices.md)** - Safety guide and best practices
- **README.md** - This file, project overview and quick reference

## Contributing

Feel free to submit issues or pull requests to improve these scripts.

For detailed version history and changes, see [CHANGELOG.md](CHANGELOG.md).

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Last Updated:** 2026
