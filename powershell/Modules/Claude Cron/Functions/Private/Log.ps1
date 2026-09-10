<#
    .SYNOPSIS
    Renames the module log out of the way once it grows past the configured size.

    .DESCRIPTION
    A drain every ten minutes writes to this file forever, so without a cap it is the one
    part of the module that grows without bound. One previous generation is kept as
    claude-cron.log.1, which is enough to investigate whatever just went wrong.
#>
function Invoke-ClaudeCronLogRotation {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal maintenance of the module log.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [int]$MaxSizeMB
    )
    if ($MaxSizeMB -le 0) { return }
    $file = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $file -or $file.Length -lt ($MaxSizeMB * 1MB)) { return }
    Move-Item -LiteralPath $Path -Destination "$Path.1" -Force -ErrorAction SilentlyContinue
}

<#
    .SYNOPSIS
    Writes a timestamped line to the module log and mirrors it to the host.

    .DESCRIPTION
    The worker usually runs detached from a terminal, so every message also lands in
    <root>/logs/claude-cron.log. INFO goes to the information stream so a cron run can
    stay quiet unless -InformationAction Continue is used.

    .PARAMETER Level
    DEBUG lines are written to the file too, but never to the host unless -Debug is on.
    Routine "nothing happened" messages use DEBUG so an idle queue stays cheap.
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
        # Cached for the life of the process: this runs on every log line, and re-reading
        # and re-parsing config.json each time would cost more than the write itself.
        if ($null -eq $script:ClaudeCronLogMaxMB) {
            $script:ClaudeCronLogMaxMB = [int](Read-ClaudeCronConfig).MaxLogSizeMB
        }
        Invoke-ClaudeCronLogRotation -Path $logFile -MaxSizeMB $script:ClaudeCronLogMaxMB
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
    The title and the message are passed to the shell as positional arguments, and the
    {title} and {message} placeholders are rewritten to "$1" and "$2" before the command
    runs. That keeps pipes and && working while making sure a job name or an error string
    can never be read as shell syntax: a job called $(rm -rf ~) is just a job name.

    Under cron there is no DBUS_SESSION_BUS_ADDRESS, so notify-send has nothing to talk
    to. Use the systemd timer, which runs inside the session, if you want desktop popups.
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

    # The quoted forms go first so notify-send "{title}" does not end up as ""$1"",
    # which sh would word-split.
    $command = [string]$config.NotifyCommand
    foreach ($pair in @(@('title', '"$1"'), @('message', '"$2"'))) {
        foreach ($form in @("`"{$($pair[0])}`"", "'{$($pair[0])}'", "{$($pair[0])}")) {
            $command = $command.Replace($form, $pair[1])
        }
    }

    try {
        if ($IsWindows) {
            # cmd.exe has no equivalent of sh's positional arguments, so the values are
            # substituted directly and the characters cmd acts on are stripped out.
            $safeTitle = $Title -replace '[&|<>^"%\r\n]', ' '
            $safeMessage = $Message -replace '[&|<>^"%\r\n]', ' '
            $literal = $command.Replace('"$1"', "`"$safeTitle`"").Replace('"$2"', "`"$safeMessage`"")
            & cmd.exe /c $literal | Out-Null
        }
        else {
            # The 'sh' after the script is $0; the two values land in $1 and $2.
            & /bin/sh -c $command 'sh' $Title $Message | Out-Null
        }
    }
    catch {
        Write-ClaudeCronLog -Level 'WARN' -Message "Notification command failed: $($_.Exception.Message)"
    }
}
