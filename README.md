# 🍫 Chocolatey Scripts for Windows

A comprehensive collection of PowerShell scripts for managing Chocolatey package manager on Windows systems. These scripts provide automated installation, app management, updates, and maintenance for Windows environments.

## 📋 Scripts Overview

### 🛠️ Core Installation Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `install-chocolatey.ps1` | Installs Chocolatey with proper configuration | `.\install-chocolatey.ps1` |
| `install-essential-apps.ps1` | Installs essential Windows applications | `.\install-essential-apps.ps1` |

### 🔄 Maintenance Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `auto-update-chocolatey.ps1` | Auto-updates with WiFi/power conditions | `.\auto-update-chocolatey.ps1` |
| `cleanup-chocolatey.ps1` | Comprehensive cleanup and maintenance | `.\cleanup-chocolatey.ps1` |

## 🚀 Quick Start

### Prerequisites
- Windows 10 or Windows 11
- PowerShell 5.1 or higher
- Administrator privileges
- Internet connection

### Installation Steps

1. **Clone or download this repository**
   ```powershell
   # Navigate to the scripts directory
   cd C:\path\to\chocolateyScripts
   ```

2. **Set PowerShell execution policy** (if needed)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Install Chocolatey**
   ```powershell
   .\install-chocolatey.ps1
   ```

4. **Install essential applications**
   ```powershell
   .\install-essential-apps.ps1
   ```

## 📦 Essential Applications Included

The `install-essential-apps.ps1` script installs these applications:

### 🌐 Web Browsers
- **Google Chrome** - Modern web browser
- **Mozilla Firefox** - Privacy-focused browser
- **Microsoft Edge** - Windows native browser

### 💻 Development Tools
- **Visual Studio Code** - Popular code editor
- **Notepad++** - Advanced text editor

### 🛠️ Utilities
- **7-Zip** - File compression utility
- **VLC Media Player** - Media player
- **Windows Terminal** - Modern terminal emulator

### 🎮 Entertainment
- **Discord** - Communication platform
- **Steam** - Gaming platform

## 🔄 Auto-Update Features

The `auto-update-chocolatey.ps1` script includes smart conditions:

### ✅ Update Conditions
- **WiFi Network**: Must be connected to "CastleEstates" WiFi
- **Power Status**: Must be plugged into power (not on battery)
- **Administrator Rights**: Runs with elevated privileges

### 📧 Notifications
- **Email Reports**: Detailed HTML reports with logs
- **Status Updates**: Success/failure notifications
- **Logging**: Comprehensive activity logging

### ⚙️ Configuration
Edit the script to customize:
```powershell
$WifiNetwork = "CastleEstates"  # Your WiFi network name
$EmailAddress = "your-email@example.com"  # Your email address
```

## 🧹 Cleanup Features

The `cleanup-chocolatey.ps1` script performs:

### 🗑️ Cleanup Operations
- **Old Versions**: Removes outdated package versions
- **Cache Cleanup**: Clears download cache
- **Orphaned Packages**: Removes unused dependencies
- **Health Check**: Runs `choco doctor` for diagnostics

### 📊 Statistics
- **Disk Usage**: Shows before/after space usage
- **Space Saved**: Reports cleanup efficiency
- **Operation Summary**: Lists successful/failed operations

## 📁 Log Files

All scripts create detailed logs in `%USERPROFILE%\Logs\`:

| Script | Log File |
|--------|----------|
| Chocolatey Install | `ChocolateyInstall.log` |
| Essential Apps | `EssentialAppsInstall.log` |
| Auto Update | `AutoUpdateChocolatey.log` |
| Cleanup | `ChocolateyCleanup.log` |

## 🔧 Troubleshooting

### Common Issues

#### PowerShell Execution Policy
```powershell
# If you get execution policy errors:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Administrator Rights
```powershell
# Right-click PowerShell and select "Run as Administrator"
# Or run this command to check:
[Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544"
```

#### Chocolatey Not Found
```powershell
# If choco command is not recognized:
refreshenv
# Or restart PowerShell
```

#### Email Notifications Not Working
1. Configure your email settings in the script
2. Update SMTP server details
3. Use app passwords for Gmail
4. Check Windows Firewall settings

### Log Analysis
```powershell
# View recent log entries:
Get-Content "$env:USERPROFILE\Logs\ChocolateyInstall.log" -Tail 20

# Search for errors:
Get-Content "$env:USERPROFILE\Logs\*.log" | Select-String "ERROR"
```

## ⚙️ Advanced Configuration

### Customizing App List
Edit `install-essential-apps.ps1` to add/remove applications:
```powershell
$apps = @(
    @{Name="Your App"; Package="your-package"; Display="Your App Name"},
    # Add more apps here
)
```

### Setting Up Auto-Update Schedule
Use Windows Task Scheduler to run auto-update automatically:

1. **Open Task Scheduler**
2. **Create Basic Task**
3. **Set Trigger**: Daily/Weekly as needed
4. **Set Action**: Start a program
5. **Program**: `powershell.exe`
6. **Arguments**: `-ExecutionPolicy Bypass -File "C:\path\to\auto-update-chocolatey.ps1"`

### Email Configuration
Update email settings in `auto-update-chocolatey.ps1`:
```powershell
$EmailAddress = "your-email@example.com"
$smtpServer = "smtp.gmail.com"  # Your SMTP server
$smtpUser = "your-email@example.com"
$smtpPass = "your-app-password"  # Use app password for Gmail
```

## 🔒 Security Considerations

### Best Practices
- **Run as Administrator**: Required for Chocolatey operations
- **Execution Policy**: Use RemoteSigned for security
- **Email Passwords**: Use app passwords, not regular passwords
- **Log Files**: Review logs regularly for security issues

### Network Security
- **WiFi Check**: Scripts verify network before updates
- **Power Check**: Prevents battery drain during updates
- **Retry Logic**: Handles network interruptions gracefully

## 📚 Additional Resources

### Chocolatey Documentation
- [Chocolatey Documentation](https://docs.chocolatey.org/)
- [Package Repository](https://community.chocolatey.org/packages)
- [Installation Guide](https://docs.chocolatey.org/en-us/choco/setup)

### PowerShell Resources
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

### Windows Task Scheduler
- [Task Scheduler Guide](https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page)

## 🤝 Contributing

### Adding New Scripts
1. Follow the existing script structure
2. Include comprehensive logging
3. Add error handling and retry logic
4. Update this README with documentation

### Reporting Issues
1. Check the log files first
2. Include system information (Windows version, PowerShell version)
3. Provide error messages and steps to reproduce

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Chocolatey Community](https://chocolatey.org/) for the excellent package manager
- [PowerShell Team](https://github.com/PowerShell/PowerShell) for the powerful scripting platform
- Windows community for feedback and improvements

---

**Note**: These scripts are designed for Windows environments and require Administrator privileges. Always review scripts before running them and ensure you understand what they do. 