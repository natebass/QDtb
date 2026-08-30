<#
    .SYNOPSIS
    Writes a timestamped line to the module log and mirrors it to the host.

    .DESCRIPTION
    The worker usually runs detached from a terminal, so every message also lands in
    <root>/logs/claude-cron.log. INFO goes to the information stream so a cron run can
    stay quiet unless -InformationAction Continue is used.
#>
function Write-ClaudeCronLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO',

        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = '{0} [{1}] {2}' -f $timestamp, $Level.PadRight(5), $Message
    try {
        $logFile = Join-Path (Get-ClaudeCronPath).Logs 'claude-cron.log'
        Add-Content -LiteralPath $logFile -Value $line -Encoding utf8
    }
    catch {
        # Never let a logging failure take down a run.
        Write-Debug "Could not write to the log file: $($_.Exception.Message)"
    }
    switch ($Level) {
        'ERROR' { Write-Error $Message }
        'WARN' { Write-Warning $Message }
        'DEBUG' { Write-Debug $Message }
        default { Write-Information $line -InformationAction Continue }
    }
}

<#
    .SYNOPSIS
    Fires the optional NotifyCommand so the desktop can announce finished work.

    .DESCRIPTION
    The configured command is run through the shell with two placeholders replaced:
    {title} and {message}. Example: notify-send "{title}" "{message}"
#>
function Send-ClaudeCronNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $config = Read-ClaudeCronConfig
    if ([string]::IsNullOrWhiteSpace($config.NotifyCommand)) { return }
    $command = $config.NotifyCommand.Replace('{title}', $Title).Replace('{message}', $Message)
    try {
        if ($IsWindows) {
            & cmd.exe /c $command | Out-Null
        }
        else {
            & /bin/sh -c $command | Out-Null
        }
    }
    catch {
        Write-ClaudeCronLog -Level 'WARN' -Message "Notification command failed: $($_.Exception.Message)"
    }
}
