# Chocolatey Scripts

PowerShell scripts for managing Chocolatey package manager on Windows systems.

## Quick Start

```powershell
# 1. Install Chocolatey
.\install-chocolatey.ps1

# 2. Install essential applications
.\install-essential-apps.ps1

# 3. Update packages (optional)
.\auto-update-chocolatey.ps1

# 4. Clean up old packages (optional)
.\cleanup-chocolatey.ps1
```

## Scripts

| Script | Description |
|--------|-------------|
| `install-chocolatey.ps1` | Installs Chocolatey package manager |
| `install-essential-apps.ps1` | Installs essential Windows applications |
| `auto-update-chocolatey.ps1` | Updates Chocolatey and packages with conditions |
| `cleanup-chocolatey.ps1` | Cleans up old package versions and cache |

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges
- Internet connection

## Essential Applications

The `install-essential-apps.ps1` script installs:

- **Browsers**: Chrome, Firefox, Edge
- **Development**: VS Code, Notepad++
- **Utilities**: 7-Zip, VLC, Windows Terminal
- **Communication**: Discord
- **Gaming**: Steam

## Configuration

### Auto-Update Conditions

The `auto-update-chocolatey.ps1` script runs when:

- Connected to "CastleEstates" WiFi
- Plugged into power (not on battery)
- Has administrator privileges

Edit these settings in the script:

```powershell
$WifiNetwork = "CastleEstates"
$EmailAddress = "your-email@example.com"
```

## Logging

All scripts log to `%USERPROFILE%\Logs\`:

- `ChocolateyInstall.log`
- `EssentialAppsInstall.log`
- `AutoUpdateChocolatey.log`
- `ChocolateyCleanup.log`

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

## License

MIT License - see [LICENSE](LICENSE) file for details.
