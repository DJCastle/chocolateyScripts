# Changelog

All notable changes to the Chocolatey Scripts project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-02-06

### 🎉 Major Release - 2026 Refresh

This is a comprehensive update bringing the project into 2026 with modern features, bug fixes, and significant improvements.

### Added

#### New Scripts

- **health-check.ps1** - Comprehensive diagnostics and health monitoring system
  - Checks Chocolatey installation status and version
  - Verifies system requirements (PowerShell, Windows version, disk space)
  - Scans for outdated packages
  - Reports configuration issues
  - Provides actionable recommendations

- **backup-packages.ps1** - Complete backup and restore solution
  - Export installed package lists to JSON format
  - Restore packages on new machines
  - List and manage multiple backup files
  - Timestamped backups with metadata
  - Perfect for disaster recovery and migration

- **setup-scheduled-tasks.ps1** - Interactive automation wizard
  - Menu-driven setup interface
  - Creates Windows scheduled tasks automatically
  - Customizable schedules (daily/weekly/monthly)
  - Manages both auto-update and cleanup tasks
  - View and remove existing tasks

- **Send-ToastNotification.ps1** - Modern notification system
  - Windows 10/11 Toast notification support
  - Can be imported by other scripts
  - Multiple notification types (Info, Success, Warning, Error)
  - Native Windows notification experience

#### Configuration

- **config.json** - Centralized configuration file
  - Single source of truth for all settings
  - WiFi network and email preferences
  - Backup location and retention policies
  - Scheduled task preferences
  - Advanced options for power users
  - Eliminates hardcoded values in scripts

- **.gitignore** - Proper version control exclusions
  - Protects sensitive configuration files
  - Excludes logs and temporary files
  - Cross-platform compatible

#### Documentation

- **CHANGELOG.md** - This file, tracking all changes
- **Enhanced README.md** with:
  - "What's New in 2026" section
  - Advanced Features documentation
  - Quick Start guide (basic and advanced)
  - Security Best Practices section
  - Performance Tips section
  - Comprehensive script descriptions

### Changed

#### Package Updates

- Added **PowerShell 7+** (powershell-core) to essential apps
- Added **Git** to essential apps for developers
- Updated package list from 10 to 12 essential applications

#### Script Improvements

- **auto-update-chocolatey.ps1**
  - Enhanced WiFi detection with better adapter matching
  - Improved regex pattern for SSID detection
  - Modernized power status check using CIM cmdlets
  - Better fallback to WMI for compatibility
  - Fixed battery status detection logic (BatteryStatus >= 2)

- **install-essential-apps.ps1**
  - Added PowerShell Core and Git to installation list
  - Improved app detection logic

- **All scripts**
  - Better error handling and retry logic
  - More informative status messages
  - Improved logging functionality

#### Documentation Updates

- Updated system requirements to recommend Windows 11 and PowerShell 7+
- Fixed all markdown linting issues
- Improved table formatting throughout
- Added blank lines around lists for proper rendering
- Enhanced code examples with better comments

#### Infrastructure

- Updated GitHub Actions workflow to Node.js 22 (LTS)
- Updated copyright year from 2024 to 2026
- Enhanced library.config.json with new script metadata

### Fixed

- **Critical Bug**: Fixed PowerShell syntax error in install-chocolatey.ps1
  - Changed bash `fi` to PowerShell `}` on line 187
  - This was preventing successful script execution

- **WiFi Detection**: Improved network adapter detection
  - Now matches both "Wi-Fi" and "Wireless" interface descriptions
  - Better SSID regex pattern: `"^\s*SSID\s*:"`

- **Power Status**: Enhanced battery detection
  - Uses modern CIM cmdlets (Get-CimInstance) instead of deprecated WMI
  - Proper fallback to WMI for older systems
  - Correct battery status interpretation (>= 2 for AC power)

- **Markdown Formatting**: Resolved all linting warnings
  - Fixed table column spacing issues
  - Added proper blank lines around lists
  - Resolved duplicate heading warnings

### Security

- Added comprehensive Security Best Practices section to README
- Created .gitignore to prevent committing sensitive data
- Documented safe script review practices
- Emphasized administrator privilege awareness

### Deprecated

- Direct use of Get-WmiObject (replaced with Get-CimInstance where possible)
- Hardcoded configuration values (moved to config.json)

### Breaking Changes

- Configuration moved to config.json
  - Scripts that previously had hardcoded values now read from config.json
  - Users upgrading should create config.json before running scripts
  - Email and WiFi settings must be configured in config.json

## [1.0.0] - 2024-09-27

### Initial Release

- install-chocolatey.ps1 - Initial Chocolatey installation script
- install-essential-apps.ps1 - Essential Windows applications installer
- auto-update-chocolatey.ps1 - Conditional automatic updates
- cleanup-chocolatey.ps1 - Package cleanup and maintenance
- README.md - Basic documentation
- GitHub Actions workflow for manifest generation

---

## Version History Summary

| Version | Date | Key Changes |
|---------|------|-------------|
| 2.0.0 | 2026-02-06 | Major refresh with 4 new scripts, centralized config, bug fixes |
| 1.0.0 | 2024-09-27 | Initial release with 4 core scripts |

## Future Roadmap

Planned features for future releases:

- [ ] Integration with Windows Package Manager (winget)
- [ ] Web dashboard for monitoring updates
- [ ] Multi-machine management support
- [ ] Package dependency visualization
- [ ] Automated testing framework
- [ ] Docker container support for testing
- [ ] PowerShell Gallery module packaging
- [ ] Integration with Microsoft Intune
- [ ] Prometheus/Grafana monitoring export
- [ ] Slack/Teams notification support

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Support

For issues, questions, or contributions, please visit:
https://github.com/DJCastle/chocolateyScripts
