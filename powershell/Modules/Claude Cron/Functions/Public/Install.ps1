$script:ClaudeCronCronBegin = '# >>> claude-cron >>>'
$script:ClaudeCronCronEnd = '# <<< claude-cron <<<'
$script:ClaudeCronUnitName = 'claude-cron'

<#
    .SYNOPSIS
    Builds the pwsh command line that a scheduler should run to drain the queue.

    .DESCRIPTION
    Cron and systemd both get a non-interactive pwsh that imports this module from the
    path it currently lives at and calls Invoke-ClaudeCronQueue once.
#>
function Get-ClaudeCronDrainCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Limit = 0
    )
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'ClaudeCron.psd1'
    $modulePath = (Resolve-Path -LiteralPath $modulePath).Path
    $call = if ($Limit -gt 0) { "Invoke-ClaudeCronQueue -Limit $Limit" } else { 'Invoke-ClaudeCronQueue' }
    $script = "Import-Module '$modulePath' -Force; $call"
    return [pscustomobject]@{
        Pwsh       = Get-ClaudeCronPwshPath
        ModulePath = $modulePath
        Arguments  = @('-NoProfile', '-NonInteractive', '-Command', $script)
        CommandLine = "$(Get-ClaudeCronPwshPath) -NoProfile -NonInteractive -Command `"$($script -replace '"', '\"')`""
    }
}

<#
    .SYNOPSIS
    Reports which schedulers are currently set up to drain the queue.

    .EXAMPLE
    Get-ClaudeCronSchedule
#>
function Get-ClaudeCronSchedule {
    [CmdletBinding()]
    param ()
    $cronLine = $null
    $timerState = $null

    if (Get-Command -Name 'crontab' -CommandType Application -ErrorAction SilentlyContinue) {
        $current = @(& crontab -l 2>$null)
        $inBlock = $false
        foreach ($line in $current) {
            if ($line -eq $script:ClaudeCronCronBegin) { $inBlock = $true; continue }
            if ($line -eq $script:ClaudeCronCronEnd) { $inBlock = $false; continue }
            if ($inBlock -and $line -and -not $line.StartsWith('#')) { $cronLine = $line }
        }
    }
    $unitFile = Join-Path $HOME ".config/systemd/user/$($script:ClaudeCronUnitName).timer"
    if (Test-Path -LiteralPath $unitFile) {
        $timerState = if (Get-Command -Name 'systemctl' -CommandType Application -ErrorAction SilentlyContinue) {
            (& systemctl --user is-enabled "$($script:ClaudeCronUnitName).timer" 2>$null) -join ''
        }
        else {
            'unknown'
        }
    }
    return [pscustomobject]@{
        CronInstalled   = [bool]$cronLine
        CronLine        = $cronLine
        TimerInstalled  = [bool]$timerState
        TimerUnitFile   = if ($timerState) { $unitFile } else { $null }
        TimerEnabled    = $timerState
    }
}

<#
    .SYNOPSIS
    Installs a crontab entry that drains the queue on a schedule.

    .DESCRIPTION
    Writes a managed block into the current user's crontab, replacing any block this
    module wrote before. Nothing outside the markers is touched. Because cron runs with
    a minimal environment, the entry uses absolute paths and sets PATH and HOME itself.

    Cron only fires while the machine is awake: see the README section on keeping Linux
    Mint from suspending if you expect overnight runs.

    .PARAMETER Cron
    The cron expression to install. Defaults to every 10 minutes.

    .PARAMETER Path
    PATH given to the cron job. Defaults to the current session's PATH, which is usually
    what you want since it can find the Claude CLI.

    .EXAMPLE
    Install-ClaudeCronSchedule -Cron '*/15 * * * *'

    .EXAMPLE
    Install-ClaudeCronSchedule -WhatIf

    Shows the crontab that would be written without changing anything.
#>
function Install-ClaudeCronSchedule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Cron = '*/10 * * * *',

        [Parameter(Mandatory = $false)]
        [string]$Path = $env:PATH
    )
    if ($IsWindows) { throw 'Install-ClaudeCronSchedule is for Linux and macOS. On Windows use Register-ScheduledTask with the command from Get-ClaudeCronDrainCommand.' }
    if (-not (Get-Command -Name 'crontab' -CommandType Application -ErrorAction SilentlyContinue)) {
        throw "crontab was not found. On Linux Mint install it with: sudo apt install cron"
    }
    [void](ConvertFrom-ClaudeCronExpression -Expression $Cron)

    $drain = Get-ClaudeCronDrainCommand
    $cronLog = Join-Path (Get-ClaudeCronPath).Logs 'cron.log'
    $entry = "$Cron $($drain.CommandLine) >> $cronLog 2>&1"

    $existing = @(& crontab -l 2>$null)
    $kept = [System.Collections.Generic.List[string]]::new()
    $inBlock = $false
    foreach ($line in $existing) {
        if ($line -eq $script:ClaudeCronCronBegin) { $inBlock = $true; continue }
        if ($line -eq $script:ClaudeCronCronEnd) { $inBlock = $false; continue }
        if (-not $inBlock) { $kept.Add($line) }
    }
    $kept.Add($script:ClaudeCronCronBegin)
    $kept.Add("SHELL=/bin/sh")
    $kept.Add("HOME=$HOME")
    $kept.Add("PATH=$Path")
    $kept.Add($entry)
    $kept.Add($script:ClaudeCronCronEnd)
    $content = ($kept -join "`n") + "`n"

    if (-not $PSCmdlet.ShouldProcess('crontab', "Install entry: $entry")) {
        Write-Information $content -InformationAction Continue
        return
    }
    $content | & crontab -
    if ($LASTEXITCODE -ne 0) { throw "crontab refused the new file (exit $LASTEXITCODE)." }
    Write-ClaudeCronLog -Level 'INFO' -Message "Installed crontab entry: $Cron"
    return Get-ClaudeCronSchedule
}

<#
    .SYNOPSIS
    Removes the crontab block written by Install-ClaudeCronSchedule.

    .EXAMPLE
    Uninstall-ClaudeCronSchedule
#>
function Uninstall-ClaudeCronSchedule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param ()
    if (-not (Get-Command -Name 'crontab' -CommandType Application -ErrorAction SilentlyContinue)) { return }
    $existing = @(& crontab -l 2>$null)
    $kept = [System.Collections.Generic.List[string]]::new()
    $inBlock = $false
    $removed = 0
    foreach ($line in $existing) {
        if ($line -eq $script:ClaudeCronCronBegin) { $inBlock = $true; $removed++; continue }
        if ($line -eq $script:ClaudeCronCronEnd) { $inBlock = $false; continue }
        if (-not $inBlock) { $kept.Add($line) }
    }
    if ($removed -eq 0) {
        Write-ClaudeCronLog -Level 'INFO' -Message 'No claude-cron block in the crontab.'
        return
    }
    if (-not $PSCmdlet.ShouldProcess('crontab', 'Remove claude-cron block')) { return }
    (($kept -join "`n") + "`n") | & crontab -
    Write-ClaudeCronLog -Level 'INFO' -Message 'Removed the crontab entry.'
}

<#
    .SYNOPSIS
    Installs a systemd user service and timer that drain the queue.

    .DESCRIPTION
    A better fit than cron when the machine sleeps: with Persistent=true the timer fires
    as soon as the machine wakes if the window was missed. Run
    'loginctl enable-linger $env:USER' once if you want it to run without being logged in.

    .PARAMETER OnCalendar
    A systemd calendar expression. Defaults to every 10 minutes.

    .PARAMETER NoStart
    Write and enable the units without starting the timer now.

    .EXAMPLE
    Install-ClaudeCronTimer -OnCalendar '*:0/15'
#>
function Install-ClaudeCronTimer {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$OnCalendar = '*:0/10',

        [Parameter(Mandatory = $false)]
        [switch]$NoStart
    )
    if ($IsWindows) { throw 'Install-ClaudeCronTimer is for Linux systems running systemd.' }
    if (-not (Get-Command -Name 'systemctl' -CommandType Application -ErrorAction SilentlyContinue)) {
        throw 'systemctl was not found; use Install-ClaudeCronSchedule instead.'
    }
    $unitDir = Join-Path $HOME '.config/systemd/user'
    if (-not (Test-Path -LiteralPath $unitDir)) { New-Item -ItemType Directory -Path $unitDir -Force | Out-Null }

    $drain = Get-ClaudeCronDrainCommand
    $name = $script:ClaudeCronUnitName
    $servicePath = Join-Path $unitDir "$name.service"
    $timerPath = Join-Path $unitDir "$name.timer"

    $service = @"
[Unit]
Description=Drain the ClaudeCron queue
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=$HOME
Environment=PATH=$env:PATH
ExecStart=$($drain.Pwsh) -NoProfile -NonInteractive -Command "Import-Module '$($drain.ModulePath)' -Force; Invoke-ClaudeCronQueue"
"@

    $timer = @"
[Unit]
Description=Drain the ClaudeCron queue on a schedule

[Timer]
OnCalendar=$OnCalendar
Persistent=true
AccuracySec=30s
Unit=$name.service

[Install]
WantedBy=timers.target
"@

    if (-not $PSCmdlet.ShouldProcess($timerPath, "Install systemd user timer ($OnCalendar)")) {
        Write-Information $service -InformationAction Continue
        Write-Information $timer -InformationAction Continue
        return
    }
    Set-Content -LiteralPath $servicePath -Value $service -Encoding utf8
    Set-Content -LiteralPath $timerPath -Value $timer -Encoding utf8
    & systemctl --user daemon-reload
    if ($NoStart) {
        & systemctl --user enable "$name.timer"
    }
    else {
        & systemctl --user enable --now "$name.timer"
    }
    Write-ClaudeCronLog -Level 'INFO' -Message "Installed systemd user timer '$name.timer' ($OnCalendar)."
    return Get-ClaudeCronSchedule
}

<#
    .SYNOPSIS
    Stops and removes the systemd user units.

    .EXAMPLE
    Uninstall-ClaudeCronTimer
#>
function Uninstall-ClaudeCronTimer {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param ()
    $name = $script:ClaudeCronUnitName
    $unitDir = Join-Path $HOME '.config/systemd/user'
    $servicePath = Join-Path $unitDir "$name.service"
    $timerPath = Join-Path $unitDir "$name.timer"
    if (-not (Test-Path -LiteralPath $timerPath)) {
        Write-ClaudeCronLog -Level 'INFO' -Message 'No claude-cron timer installed.'
        return
    }
    if (-not $PSCmdlet.ShouldProcess($timerPath, 'Remove systemd user timer')) { return }
    if (Get-Command -Name 'systemctl' -CommandType Application -ErrorAction SilentlyContinue) {
        & systemctl --user disable --now "$name.timer" 2>$null
    }
    Remove-Item -LiteralPath $timerPath, $servicePath -Force -ErrorAction SilentlyContinue
    if (Get-Command -Name 'systemctl' -CommandType Application -ErrorAction SilentlyContinue) {
        & systemctl --user daemon-reload
    }
    Write-ClaudeCronLog -Level 'INFO' -Message 'Removed the systemd user timer.'
}
