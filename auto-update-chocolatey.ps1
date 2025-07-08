#Requires -Version 5.1

###############################################################################
# 🔄 Auto Update Chocolatey Script for Windows
# -------------------------------------------
# This script automatically updates Chocolatey and installed applications
# with smart conditions and notifications:
#
# ✅ CONDITIONS:
#   - Must be connected to "CastleEstates" WiFi network
#   - Must be plugged into power (not on battery)
#   - Runs in background with email notifications
#
# ✅ FEATURES:
#   - Updates Chocolatey itself
#   - Updates all installed packages
#   - Sends email notifications with results
#   - Logs all activity for troubleshooting
#   - Safe to run multiple times
#
# 🔧 USAGE INSTRUCTIONS:
# 1. Make sure Chocolatey is installed first:
#      .\install-chocolatey.ps1
# 2. Run manually:
#      .\auto-update-chocolatey.ps1
# 3. Set up automatic execution (see README for Task Scheduler setup)
#
# 📁 Log output is saved to:
#      $env:USERPROFILE\Logs\AutoUpdateChocolatey.log
#
# 📧 NOTIFICATIONS:
# - Uses Windows built-in email functionality
# - Sends detailed reports with logs
# - Requires email configuration in Windows
#
# ℹ️ Requirements:
#   - Chocolatey must be installed
#   - Windows with Administrator privileges
#   - Email configured in Windows Mail app
###############################################################################

# Set up logging
$LogPath = "$env:USERPROFILE\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = "$LogPath\AutoUpdateChocolatey.log"
Add-Content -Path $LogFile -Value "Starting Auto Update Chocolatey at $(Get-Date)"

# Configuration
$WifiNetwork = "CastleEstates"
$EmailAddress = "your-email@example.com"  # Replace with your email
$MaxRetries = 3
$RetryDelay = 300  # 5 minutes

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

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
    Add-Content -Path $LogFile -Value "[WARNING] $Message"
}

function Write-Error {
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

        # Send email using PowerShell
        $smtpServer = "smtp.gmail.com"  # Change to your SMTP server
        $smtpPort = 587
        $smtpUser = $EmailAddress
        $smtpPass = "your-password"  # Replace with your password or use secure method
        
        $smtp = New-Object System.Net.Mail.MailMessage
        $smtp.From = $EmailAddress
        $smtp.To.Add($EmailAddress)
        $smtp.Subject = $Subject
        $smtp.IsBodyHtml = $true
        $smtp.Body = $emailBody
        
        $smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
        $smtpClient.EnableSsl = $true
        $smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPass)
        
        $smtpClient.Send($smtp)
        $smtpClient.Dispose()
        
        Write-Success "Email notification sent successfully"
        return $true
    }
    catch {
        Write-Error "Failed to send email notification: $($_.Exception.Message)"
        return $false
    }
}

# Function to check WiFi network with retry
function Test-WifiNetwork {
    $retryCount = 0
    
    while ($retryCount -lt $MaxRetries) {
        try {
            $wifi = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -like "*Wi-Fi*" }
            if ($wifi) {
                $currentNetwork = (netsh wlan show interfaces | Select-String "SSID" | Select-Object -First 1) -replace ".*:\s*", ""
                
                if ($currentNetwork -eq $WifiNetwork) {
                    Write-Success "Connected to $WifiNetwork WiFi"
                    return $true
                }
                else {
                    Write-Warning "Not connected to $WifiNetwork WiFi (current: $currentNetwork)"
                }
            }
            else {
                Write-Warning "No WiFi adapter found"
            }
        }
        catch {
            Write-Warning "Could not check WiFi network: $($_.Exception.Message)"
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
        $powerStatus = Get-WmiObject -Class Win32_Battery | Select-Object -First 1
        if ($powerStatus) {
            if ($powerStatus.BatteryStatus -eq 1) {
                Write-Success "Device is plugged into power"
                return $true
            }
            else {
                Write-Warning "Device is running on battery power"
                return $false
            }
        }
        else {
            Write-Success "No battery detected - assuming desktop computer"
            return $true
        }
    }
    catch {
        Write-Warning "Could not check power status: $($_.Exception.Message)"
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
    
    # Clean up old versions
    Write-Status "Cleaning up old versions..."
    try {
        choco cleanup all -y | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            $updateSummary += "✅ Cleanup completed successfully<br>"
            $successCount++
        }
        else {
            $errors += "❌ Cleanup failed<br>"
            $errorCount++
        }
    }
    catch {
        $errors += "❌ Cleanup failed<br>"
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
        Write-Error "This script must be run as Administrator. Please right-click PowerShell and select 'Run as Administrator'."
        Send-EmailNotification "❌ Auto Update Chocolatey Failed" "Script must be run as Administrator."
        exit 1
    }
    
    # Check if Chocolatey is installed
    if (-not (Test-ChocolateyInstalled)) {
        Write-Error "Chocolatey is not installed. Please run .\install-chocolatey.ps1 first."
        Send-EmailNotification "❌ Auto Update Chocolatey Failed" "Chocolatey is not installed. Please run .\install-chocolatey.ps1 first."
        exit 1
    }
    
    # Check WiFi network with retry
    if (-not (Test-WifiNetwork)) {
        Write-Warning "Skipping update - not on $WifiNetwork WiFi after $MaxRetries attempts"
        Send-EmailNotification "⚠️ Auto Update Chocolatey Skipped" "Update skipped because not connected to $WifiNetwork WiFi network."
        exit 0
    }
    
    # Check power status
    if (-not (Test-PowerStatus)) {
        Write-Warning "Skipping update - not plugged into power"
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