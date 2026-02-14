#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
    Automatically updates Chocolatey and installed packages with conditions.

.DESCRIPTION
    Updates Chocolatey and packages when connected to specific WiFi and on power.
    Sends email notifications with results.

.NOTES
    Requires specific WiFi network and power connection.
    Logs to: $env:USERPROFILE\Logs\AutoUpdateChocolatey.log
#>

# Set up logging
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\AutoUpdateChocolatey.log"
Add-Content -Path $LogFile -Value "Starting Auto Update Chocolatey at $(Get-Date)"

# Load configuration from config.json
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = Get-Location }
$ConfigPath = Join-Path $ScriptDir "config.json"

if (Test-Path $ConfigPath) {
    try {
        $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $WifiNetwork = $Config.wifiNetwork
        $EmailAddress = $Config.emailAddress
        $MaxRetries = if ($Config.maxRetries) { $Config.maxRetries } else { 3 }
        $RetryDelay = if ($Config.retryDelaySeconds) { $Config.retryDelaySeconds } else { 300 }
    }
    catch {
        Write-Host "[WARNING] Could not parse config.json, using defaults" -ForegroundColor Yellow
        $WifiNetwork = "YOUR_WIFI_NAME"
        $EmailAddress = "your-email@example.com"
        $MaxRetries = 3
        $RetryDelay = 300
    }
}
else {
    Write-Host "[WARNING] config.json not found. Copy config.example.json to config.json and customize it." -ForegroundColor Yellow
    $WifiNetwork = "YOUR_WIFI_NAME"
    $EmailAddress = "your-email@example.com"
    $MaxRetries = 3
    $RetryDelay = 300
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

# Function to send email notification
function Send-EmailNotification {
    param(
        [string]$Subject,
        [string]$Body
    )
    
    try {
        # Create email content
        $emailBody = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .success { color: #28a745; }
        .error { color: #dc3545; }
        .warning { color: #ffc107; }
        .log { background-color: #f8f9fa; padding: 10px; border-radius: 5px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="header">
        <h2>🔄 Auto Update Chocolatey Report</h2>
        <p><strong>Date:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Computer:</strong> $env:COMPUTERNAME</p>
    </div>
    
    <div>
        $Body
    </div>
    
    <div class="log">
        <h3>📋 Recent Log Entries:</h3>
        <pre>$(Get-Content $LogFile -Tail 20 | Out-String)</pre>
    </div>
    
    <hr>
    <p><em>This is an automated message from your Chocolatey update script.</em></p>
</body>
</html>
"@

        # Load SMTP settings from config or use defaults
        $smtpServer = if ($Config.smtpServer) { $Config.smtpServer } else { "smtp.gmail.com" }
        $smtpPort = if ($Config.smtpPort) { $Config.smtpPort } else { 587 }
        $smtpUser = $EmailAddress

        # Load SMTP credentials securely from credential file
        # To create: Get-Credential | Export-Clixml (Join-Path $ScriptDir "smtp-credential.xml")
        $credPath = Join-Path $ScriptDir "smtp-credential.xml"
        if (-not (Test-Path $credPath)) {
            Write-LogError "SMTP credential file not found. To set up email notifications, run:"
            Write-Host '  Get-Credential | Export-Clixml "smtp-credential.xml"' -ForegroundColor Cyan
            Write-Host "  Use your email as the username and an App Password as the password." -ForegroundColor Cyan
            return $false
        }
        $credential = Import-Clixml $credPath

        $smtp = New-Object System.Net.Mail.MailMessage
        $smtp.From = $EmailAddress
        $smtp.To.Add($EmailAddress)
        $smtp.Subject = $Subject
        $smtp.IsBodyHtml = $true
        $smtp.Body = $emailBody

        $smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
        $smtpClient.EnableSsl = $true
        $smtpClient.Credentials = $credential

        $smtpClient.Send($smtp)
        $smtpClient.Dispose()
        
        Write-Success "Email notification sent successfully"
        return $true
    }
    catch {
        Write-LogError "Failed to send email notification: $($_.Exception.Message)"
        return $false
    }
}

# Function to check WiFi network with retry
function Test-WifiNetwork {
    $retryCount = 0

    while ($retryCount -lt $MaxRetries) {
        try {
            # Try modern method first (Windows 10/11)
            $wifi = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and ($_.InterfaceDescription -like "*Wi-Fi*" -or $_.InterfaceDescription -like "*Wireless*") }
            if ($wifi) {
                $currentNetwork = (netsh wlan show interfaces | Select-String "^\s*SSID\s*:" | Select-Object -First 1) -replace ".*:\s*", ""

                if ($currentNetwork -eq $WifiNetwork) {
                    Write-Success "Connected to $WifiNetwork WiFi"
                    return $true
                }
                else {
                    Write-LogWarning "Not connected to $WifiNetwork WiFi (current: $currentNetwork)"
                }
            }
            else {
                Write-LogWarning "No WiFi adapter found or no WiFi connection active"
            }
        }
        catch {
            Write-LogWarning "Could not check WiFi network: $($_.Exception.Message)"
        }

        $retryCount++

        if ($retryCount -lt $MaxRetries) {
            Write-Status "Retrying in $RetryDelay seconds... (attempt $retryCount/$MaxRetries)"
            Start-Sleep $RetryDelay
        }
    }

    return $false
}

# Function to check if plugged into power
function Test-PowerStatus {
    try {
        # Try modern CIM method first (preferred for Windows 10/11)
        $powerStatus = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $powerStatus) {
            # Fallback to WMI if CIM not available
            $powerStatus = Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        }

        if ($powerStatus) {
            # BatteryStatus: 1 = Discharging, 2 = AC, 3 = Fully Charged, 4-11 = various charging states
            if ($powerStatus.BatteryStatus -ge 2) {
                Write-Success "Device is plugged into power"
                return $true
            }
            else {
                Write-LogWarning "Device is running on battery power"
                return $false
            }
        }
        else {
            Write-Success "No battery detected - assuming desktop computer"
            return $true
        }
    }
    catch {
        Write-LogWarning "Could not check power status: $($_.Exception.Message)"
        return $true  # Assume desktop if we can't check
    }
}

# Function to check if Chocolatey is installed
function Test-ChocolateyInstalled {
    try {
        $null = Get-Command choco -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to perform Chocolatey updates
function Update-Chocolatey {
    $updateSummary = ""
    $errors = ""
    $successCount = 0
    $errorCount = 0
    $updatedPackages = 0
    
    Write-Status "Starting Chocolatey updates..."
    
    # Update Chocolatey itself
    Write-Status "Updating Chocolatey..."
    try {
        choco upgrade chocolatey -y | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            $updateSummary += "✅ Chocolatey updated successfully<br>"
            $successCount++
        }
        else {
            $errors += "❌ Chocolatey update failed<br>"
            $errorCount++
        }
    }
    catch {
        $errors += "❌ Chocolatey update failed<br>"
        $errorCount++
    }
    
    # Upgrade all packages
    Write-Status "Upgrading all packages..."
    try {
        $upgradeOutput = choco upgrade all -y 2>&1
        $upgradeOutput | Tee-Object -FilePath $LogFile -Append
        
        if ($LASTEXITCODE -eq 0) {
            $updateSummary += "✅ All packages upgraded successfully<br>"
            $updatedPackages = ($upgradeOutput | Select-String "upgraded" | Measure-Object).Count
            $successCount++
        }
        else {
            $errors += "❌ Package upgrade failed<br>"
            $errorCount++
        }
    }
    catch {
        $errors += "❌ Package upgrade failed<br>"
        $errorCount++
    }
    
    # Clean up Chocolatey temp/cache files
    Write-Status "Cleaning up temporary files..."
    try {
        $chocoTemp = Join-Path $env:TEMP "chocolatey"
        if (Test-Path $chocoTemp) {
            Remove-Item $chocoTemp -Recurse -Force -ErrorAction SilentlyContinue
        }
        $updateSummary += "✅ Temp files cleaned successfully<br>"
        $successCount++
    }
    catch {
        $errors += "❌ Temp cleanup failed<br>"
        $errorCount++
    }
    
    # Return results
    return @{
        Summary = $updateSummary
        Errors = $errors
        SuccessCount = $successCount
        ErrorCount = $errorCount
        UpdatedPackages = $updatedPackages
    }
}

# Main execution
function Main {
    Write-Status "Auto Update Chocolatey started at $(Get-Date)"
    
    # Check if running as Administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-LogError "This script must be run as Administrator. Please right-click PowerShell and select 'Run as Administrator'."
        Send-EmailNotification "❌ Auto Update Chocolatey Failed" "Script must be run as Administrator."
        exit 1
    }
    
    # Check if Chocolatey is installed
    if (-not (Test-ChocolateyInstalled)) {
        Write-LogError "Chocolatey is not installed. Please run .\install-chocolatey.ps1 first."
        Send-EmailNotification "❌ Auto Update Chocolatey Failed" "Chocolatey is not installed. Please run .\install-chocolatey.ps1 first."
        exit 1
    }
    
    # Check WiFi network with retry
    if (-not (Test-WifiNetwork)) {
        Write-LogWarning "Skipping update - not on $WifiNetwork WiFi after $MaxRetries attempts"
        Send-EmailNotification "⚠️ Auto Update Chocolatey Skipped" "Update skipped because not connected to $WifiNetwork WiFi network."
        exit 0
    }
    
    # Check power status
    if (-not (Test-PowerStatus)) {
        Write-LogWarning "Skipping update - not plugged into power"
        Send-EmailNotification "⚠️ Auto Update Chocolatey Skipped" "Update skipped because device is running on battery power."
        exit 0
    }
    
    # All conditions met, proceed with updates
    Write-Success "All conditions met. Proceeding with updates..."
    
    # Perform updates
    $updateResults = Update-Chocolatey
    
    # Prepare notification message
    $emailBody = ""
    if ($updateResults.ErrorCount -eq 0) {
        $emailBody += "<h3 class='success'>🎉 All updates completed successfully!</h3>"
    }
    else {
        $emailBody += "<h3 class='warning'>⚠️ Some updates had issues</h3>"
    }
    
    $emailBody += "<p><strong>Summary:</strong></p>"
    $emailBody += "<ul>"
    $emailBody += "<li>✅ Successful operations: $($updateResults.SuccessCount)</li>"
    $emailBody += "<li>❌ Errors: $($updateResults.ErrorCount)</li>"
    $emailBody += "<li>📦 Packages updated: $($updateResults.UpdatedPackages)</li>"
    $emailBody += "</ul>"
    
    if ($updateResults.Summary) {
        $emailBody += "<p><strong>Details:</strong></p>"
        $emailBody += "<p>$($updateResults.Summary)</p>"
    }
    
    if ($updateResults.Errors) {
        $emailBody += "<p><strong>Errors:</strong></p>"
        $emailBody += "<p class='error'>$($updateResults.Errors)</p>"
    }
    
    # Send notification
    $emailSubject = "🔄 Auto Update Chocolatey - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Send-EmailNotification -Subject $emailSubject -Body $emailBody
    
    Write-Success "Auto Update Chocolatey completed at $(Get-Date)"
    Write-Status "Check log file for details: $LogFile"
}

# Run main function
Main 