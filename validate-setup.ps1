#Requires -Version 5.1

<#
.SYNOPSIS
    Validates Chocolatey Scripts setup and configuration.

.DESCRIPTION
    Checks that all scripts are present, configuration is valid, and system
    meets requirements. Provides setup recommendations and validation results.

.NOTES
    Safe to run without administrator privileges.
    Can be run before or after installation to verify setup.
#>

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

function Write-ValidationHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Cyan
    Write-Host " $Title" -ForegroundColor $Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Cyan
}

function Write-Pass {
    param([string]$Message)
    Write-Host "  [✓] $Message" -ForegroundColor $Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  [✗] $Message" -ForegroundColor $Red
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor $Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "  [i] $Message" -ForegroundColor $Blue
}

# Track validation results
$script:PassCount = 0
$script:FailCount = 0
$script:WarnCount = 0

# Validation: Check required scripts exist
function Test-RequiredScripts {
    Write-ValidationHeader "Validating Script Files"

    $requiredScripts = @(
        "install-chocolatey.ps1",
        "install-essential-apps.ps1",
        "auto-update-chocolatey.ps1",
        "cleanup-chocolatey.ps1",
        "health-check.ps1",
        "backup-packages.ps1",
        "setup-scheduled-tasks.ps1",
        "Send-ToastNotification.ps1",
        "validate-setup.ps1"
    )

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $scriptDir) { $scriptDir = Get-Location }

    foreach ($script in $requiredScripts) {
        $path = Join-Path $scriptDir $script
        if (Test-Path $path) {
            Write-Pass "$script exists"
            $script:PassCount++
        }
        else {
            Write-Fail "$script is missing"
            $script:FailCount++
        }
    }
}

# Validation: Check configuration files
function Test-ConfigurationFiles {
    Write-ValidationHeader "Validating Configuration"

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $scriptDir) { $scriptDir = Get-Location }

    # Check config.json exists
    $configPath = Join-Path $scriptDir "config.json"
    if (Test-Path $configPath) {
        Write-Pass "config.json exists"
        $script:PassCount++

        # Validate JSON syntax
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            Write-Pass "config.json has valid JSON syntax"
            $script:PassCount++

            # Check for default values that should be customized
            $needsCustomization = @()

            if ($config.wifiNetwork -eq "YOUR_WIFI_NAME") {
                $needsCustomization += "wifiNetwork"
            }

            if ($config.emailAddress -eq "your-email@example.com") {
                $needsCustomization += "emailAddress"
            }

            if ($needsCustomization.Count -gt 0) {
                Write-Warn "config.json contains default values for: $($needsCustomization -join ', ')"
                Write-Info "Edit config.json to customize these settings"
                $script:WarnCount++
            }
            else {
                Write-Pass "config.json appears to be customized"
                $script:PassCount++
            }
        }
        catch {
            Write-Fail "config.json has invalid JSON syntax: $($_.Exception.Message)"
            $script:FailCount++
        }
    }
    else {
        Write-Fail "config.json is missing"
        $script:FailCount++
    }

    # Check for README and documentation
    $readmePath = Join-Path $scriptDir "README.md"
    if (Test-Path $readmePath) {
        Write-Pass "README.md exists"
        $script:PassCount++
    }
    else {
        Write-Warn "README.md is missing"
        $script:WarnCount++
    }

    # Check for .gitignore
    $gitignorePath = Join-Path $scriptDir ".gitignore"
    if (Test-Path $gitignorePath) {
        Write-Pass ".gitignore exists (protects sensitive files)"
        $script:PassCount++
    }
    else {
        Write-Warn ".gitignore is missing"
        $script:WarnCount++
    }
}

# Validation: Check system requirements
function Test-SystemRequirements {
    Write-ValidationHeader "Validating System Requirements"

    # PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Info "PowerShell version: $psVersion"

    if ($psVersion.Major -ge 7) {
        Write-Pass "PowerShell 7+ detected (excellent)"
        $script:PassCount++
    }
    elseif ($psVersion.Major -ge 5) {
        Write-Warn "PowerShell 5.x detected (works, but 7+ recommended)"
        $script:WarnCount++
    }
    else {
        Write-Fail "PowerShell version too old (minimum 5.1 required)"
        $script:FailCount++
    }

    # Windows version
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        Write-Info "OS: $($os.Caption) (Build $($os.BuildNumber))"

        if ($os.BuildNumber -ge 22000) {
            Write-Pass "Windows 11 detected"
            $script:PassCount++
        }
        elseif ($os.BuildNumber -ge 10240) {
            Write-Pass "Windows 10 detected"
            $script:PassCount++
        }
        else {
            Write-Warn "Windows version may not be fully supported"
            $script:WarnCount++
        }
    }
    catch {
        Write-Warn "Could not determine Windows version"
        $script:WarnCount++
    }

    # Disk space
    try {
        $systemDrive = $env:SystemDrive
        $drive = Get-PSDrive $systemDrive.TrimEnd(':')
        $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
        Write-Info "Free disk space on $systemDrive : $freeSpaceGB GB"

        if ($freeSpaceGB -ge 10) {
            Write-Pass "Sufficient disk space available"
            $script:PassCount++
        }
        elseif ($freeSpaceGB -ge 5) {
            Write-Warn "Disk space is getting low (less than 10 GB)"
            $script:WarnCount++
        }
        else {
            Write-Fail "Critically low disk space (less than 5 GB)"
            $script:FailCount++
        }
    }
    catch {
        Write-Warn "Could not check disk space"
        $script:WarnCount++
    }

    # Execution policy
    try {
        $executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
        Write-Info "Execution policy (CurrentUser): $executionPolicy"

        if ($executionPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")) {
            Write-Pass "Execution policy allows script execution"
            $script:PassCount++
        }
        elseif ($executionPolicy -eq "Restricted") {
            Write-Fail "Execution policy is Restricted (blocks scripts)"
            Write-Info "Fix with: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
            $script:FailCount++
        }
        else {
            Write-Warn "Execution policy is set to: $executionPolicy"
            $script:WarnCount++
        }
    }
    catch {
        Write-Warn "Could not check execution policy"
        $script:WarnCount++
    }

    # Administrator check
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Info "Running with administrator privileges"
    }
    else {
        Write-Info "Not running as administrator (OK for validation)"
    }
}

# Validation: Check Chocolatey installation
function Test-ChocolateyInstallation {
    Write-ValidationHeader "Validating Chocolatey Installation"

    try {
        $chocoCmd = Get-Command choco -ErrorAction Stop
        Write-Pass "Chocolatey is installed"
        $script:PassCount++

        # Get version
        $version = choco --version 2>$null
        if ($version) {
            Write-Info "Chocolatey version: $version"
        }

        # Check environment variable
        if ($env:ChocolateyInstall) {
            Write-Pass "ChocolateyInstall environment variable is set"
            $script:PassCount++

            if (Test-Path $env:ChocolateyInstall) {
                Write-Pass "Chocolatey directory exists at: $env:ChocolateyInstall"
                $script:PassCount++
            }
            else {
                Write-Fail "Chocolatey directory not found"
                $script:FailCount++
            }
        }
        else {
            Write-Warn "ChocolateyInstall environment variable not set"
            $script:WarnCount++
        }
    }
    catch {
        Write-Info "Chocolatey is not installed yet"
        Write-Info "Run .\install-chocolatey.ps1 to install"
    }
}

# Validation: Check log directory
function Test-LogDirectory {
    Write-ValidationHeader "Validating Log Configuration"

    $logPath = "$env:USERPROFILE\Logs"

    if (Test-Path $logPath) {
        Write-Pass "Log directory exists at: $logPath"
        $script:PassCount++

        # Check for existing logs
        $logFiles = Get-ChildItem $logPath -Filter "*.log" -ErrorAction SilentlyContinue
        if ($logFiles) {
            Write-Info "Found $($logFiles.Count) existing log file(s)"
            $totalSize = ($logFiles | Measure-Object -Property Length -Sum).Sum
            $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
            Write-Info "Total log size: $totalSizeMB MB"

            if ($totalSizeMB -gt 100) {
                Write-Warn "Log files are getting large (over 100 MB)"
                Write-Info "Consider archiving or cleaning old logs"
                $script:WarnCount++
            }
        }
    }
    else {
        Write-Info "Log directory will be created on first script run"
    }
}

# Generate summary report
function Show-ValidationSummary {
    Write-ValidationHeader "Validation Summary"

    $totalChecks = $script:PassCount + $script:FailCount + $script:WarnCount

    Write-Host ""
    Write-Host "  Total Checks: $totalChecks" -ForegroundColor White
    Write-Host "  ✓ Passed:     $script:PassCount" -ForegroundColor Green
    Write-Host "  ✗ Failed:     $script:FailCount" -ForegroundColor Red
    Write-Host "  ! Warnings:   $script:WarnCount" -ForegroundColor Yellow
    Write-Host ""

    if ($script:FailCount -eq 0 -and $script:WarnCount -eq 0) {
        Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║  🎉 Perfect! Setup is complete and valid.     ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Info "You're ready to use all scripts!"
        Write-Info "Recommended next steps:"
        Write-Host "  1. Customize config.json for your environment" -ForegroundColor Cyan
        Write-Host "  2. Run .\health-check.ps1 for detailed diagnostics" -ForegroundColor Cyan
        Write-Host "  3. Create initial backup with .\backup-packages.ps1" -ForegroundColor Cyan
        Write-Host "  4. Setup automation with .\setup-scheduled-tasks.ps1" -ForegroundColor Cyan
    }
    elseif ($script:FailCount -eq 0) {
        Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║  ⚠️  Setup is mostly complete with warnings.  ║" -ForegroundColor Yellow
        Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Info "Review warnings above and address them if needed."
    }
    else {
        Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║  ❌ Setup has issues that need attention.     ║" -ForegroundColor Red
        Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host ""
        Write-Info "Please address the failed checks above."
        Write-Info "See GETTING_STARTED.md for detailed setup instructions."
    }

    Write-Host ""
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
    Write-Host "║     Chocolatey Scripts - Setup Validation Tool             ║" -ForegroundColor $Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan

    # Run all validations
    Test-RequiredScripts
    Test-ConfigurationFiles
    Test-SystemRequirements
    Test-ChocolateyInstallation
    Test-LogDirectory

    # Show summary
    Show-ValidationSummary

    # Return exit code
    if ($script:FailCount -eq 0) {
        exit 0
    }
    else {
        exit 1
    }
}

# Run main function
Main
