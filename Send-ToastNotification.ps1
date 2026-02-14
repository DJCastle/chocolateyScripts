#Requires -Version 5.1

<#
.SYNOPSIS
    Sends Windows Toast notifications.

.DESCRIPTION
    Helper function to send modern Windows 10/11 Toast notifications.
    Can be imported by other scripts for notification functionality.

.PARAMETER Title
    The title of the toast notification

.PARAMETER Message
    The message body of the toast notification

.PARAMETER Type
    The type of notification: Info, Success, Warning, or Error

.EXAMPLE
    .\Send-ToastNotification.ps1 -Title "Update Complete" -Message "Chocolatey updated successfully" -Type Success

.NOTES
    Requires Windows 10/11
    Works best when called from scheduled tasks or interactive sessions
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Title,

    [Parameter(Mandatory=$true)]
    [string]$Message,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Info", "Success", "Warning", "Error")]
    [string]$Type = "Info"
)

function Send-ToastNotification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Type = "Info"
    )

    try {
        # Check if running on Windows 10/11
        $osVersion = [System.Environment]::OSVersion.Version
        if ($osVersion.Major -lt 10) {
            Write-Warning "Toast notifications require Windows 10 or later"
            return $false
        }

        # Load required assemblies
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        # App ID for notification
        $AppId = "Chocolatey.PackageManager"

        # Icon URL
        $iconUri = "https://raw.githubusercontent.com/chocolatey/choco/main/docs/images/chocolatey-icon.png"

        # XML-escape parameters to prevent injection
        $safeTitle = [System.Security.SecurityElement]::Escape($Title)
        $safeMessage = [System.Security.SecurityElement]::Escape($Message)

        # Create XML template for toast
        $toastXml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$safeTitle</text>
            <text>$safeMessage</text>
            <image placement="appLogoOverride" hint-crop="circle" src="$iconUri"/>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default" />
</toast>
"@

        # Load XML
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($toastXml)

        # Create notification
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)

        # Show notification
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($toast)

        return $true
    }
    catch {
        Write-Warning "Failed to send toast notification: $($_.Exception.Message)"
        Write-Host "Title: $Title"
        Write-Host "Message: $Message"
        return $false
    }
}

# If running as script (not dot-sourced), execute the function
if ($MyInvocation.InvocationName -ne '.') {
    Send-ToastNotification -Title $Title -Message $Message -Type $Type
}
