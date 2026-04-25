<#
    .SYNOPSIS
    Writes a log message to the log file and optionally to the console.
#>
function Write-Log {
    param ([string]$level = "INFO", [string]$message)
    $logFile = "script.log"
    $logFormat = "{0} - {1} - {2}"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = $logFormat -f $timestamp, $level, $message
    Add-Content -Path $logFile -Value $logMessage
    if ($level -eq "ERROR") { Write-Error $message } else { Write-Output $message }
}
