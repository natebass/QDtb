<#
    .SYNOPSIS
    Writes a log message to the log file and optionally to the console.
#>
function Write-ModuleLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Level = "INFO",
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $logFile = "script.log"
    $logFormat = "{0} - {1} - {2}"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = $logFormat -f $timestamp, $Level, $Message
    Add-Content -Path $logFile -Value $logMessage
    if ($Level -eq "ERROR") { Write-Error $Message } else { Write-Output $Message }
}
