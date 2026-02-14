# Changelog

## v2.0.0 — 2026 Edition (February 2026)

### New Scripts

- **health-check.ps1** — Diagnostics tool that checks your Chocolatey installation, outdated packages, disk usage, and configuration
- **backup-packages.ps1** — Backup and restore your installed package list (great for setting up a new PC)
- **setup-scheduled-tasks.ps1** — Interactive wizard to schedule automatic updates and cleanup
- **Send-ToastNotification.ps1** — Windows 10/11 toast notification helper used by other scripts

### Improvements

- Added PowerShell 7+ and Git to the essential apps list
- Smarter WiFi detection (works with more wireless adapter types)
- Modern power status checks using CIM cmdlets with WMI fallback
- Centralized configuration via `config.example.json` — copy to `config.json` and customize
- Better error handling and retry logic across all scripts

### Bug Fixes

- Fixed a syntax error in install-chocolatey.ps1 that prevented it from running
- Fixed battery status detection so updates only run when plugged in
- Improved SSID detection regex for more reliable WiFi checks

---

## v1.0.0 — Initial Release (September 2024)

- **install-chocolatey.ps1** — Install Chocolatey package manager
- **install-essential-apps.ps1** — Batch install essential Windows apps
- **auto-update-chocolatey.ps1** — Automatic updates with WiFi and power checks
- **cleanup-chocolatey.ps1** — Package cleanup and maintenance
