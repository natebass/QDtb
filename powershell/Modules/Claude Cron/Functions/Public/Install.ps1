$script:ClaudeCronCronBegin = '# >>> claude-cron >>>'
$script:ClaudeCronCronEnd = '# <<< claude-cron <<<'
$script:ClaudeCronUnitName = 'claude-cron'

<#
    .SYNOPSIS
    Reads the current user's crontab, telling an empty crontab apart from a failure.

    .DESCRIPTION
    This is the difference between editing a crontab and destroying one. 'crontab -l'
    exits non-zero both when there is no crontab yet and when it could not read the one
    that exists, and the caller writes back whatever this returns. Treating the second
    case as "no entries" replaces every job the user has with the claude-cron block, so
    anything that is not a recognised "no crontab for <user>" is raised instead.
#>
function Read-ClaudeCronCrontab {
    [CmdletBinding()]
    param ()
    if (-not (Get-Command -Name 'crontab' -CommandType Application -ErrorAction SilentlyContinue)) {
        throw "crontab was not found. On Linux Mint install it with: sudo apt install cron"
    }
    # 2>&1 rather than a redirect to a temp file: the file redirection operator honours
    # $WhatIfPreference, so under -WhatIf the stderr would silently go nowhere and an
    # absent crontab would look like an unreadable one.
    $captured = @(& crontab -l 2>&1)
    $exitCode = $LASTEXITCODE

    $errorRecords = @($captured | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
    $lines = @($captured | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ })
    $details = ($errorRecords | ForEach-Object { [string]$_ }) -join ' '

    if ($exitCode -ne 0) {
        # An empty crontab and an unreadable one both exit non-zero; only the first is safe
        # to treat as "no entries", because the caller writes back whatever comes out here.
        if ($details -match 'no crontab for') { return @() }
        throw "Refusing to touch the crontab: 'crontab -l' exited $exitCode ($($details.Trim()))."
    }
    return $lines
}

<#
    .SYNOPSIS
    Replaces the current user's crontab with the given content.

    .DESCRIPTION
    A named wrapper around 'crontab -' rather than a bare pipe at each call site, so the
    tests can substitute it and assert on exactly what would be installed without a real
    crontab being involved at any point.
#>
function Write-ClaudeCronCrontab {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal helper; the exported command that calls it declares ShouldProcess.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )
    $Content | & crontab -
    if ($LASTEXITCODE -ne 0) { throw "crontab refused the new file (exit $LASTEXITCODE); your crontab is unchanged." }
}

<#
    .SYNOPSIS
    Escapes the characters cron reads specially in a command.

    .DESCRIPTION
    An unescaped % ends the command and starts feeding the rest of the line to it on
    stdin, so a % anywhere in a path silently truncates the entry.
#>
function ConvertTo-ClaudeCronCommandField {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    return $Command.Replace('%', '\%')
}

<#
    .SYNOPSIS
    Builds the pwsh command line that a scheduler should run to drain the queue.

    .DESCRIPTION
    Cron and systemd both get a non-interactive pwsh that imports this module from the
    path it currently lives at and calls Invoke-ClaudeCronQueue once.

    The store root is resolved now and baked in, because neither cron nor systemd
    inherits the XDG_CONFIG_HOME an interactive shell may have set; without it the
    scheduler would quietly drain a different queue from the one you can see.
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
    # A single quote inside the path would end the string, so it is doubled the PowerShell way.
    $quotedPath = $modulePath.Replace("'", "''")
    $script = "Import-Module '$quotedPath' -Force; $call"
    $pwsh = Get-ClaudeCronPwshPath
    return [pscustomobject]@{
        Pwsh        = $pwsh
        ModulePath  = $modulePath
        Root        = Get-ClaudeCronRoot
        Arguments   = @('-NoProfile', '-NonInteractive', '-Command', $script)
        CommandLine = "$pwsh -NoProfile -NonInteractive -Command `"$($script -replace '"', '\"')`""
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
        # Reporting must not throw just because the crontab is unreadable.
        $current = try { Read-ClaudeCronCrontab } catch { @() }
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
        CronInstalled  = [bool]$cronLine
        CronLine       = $cronLine
        TimerInstalled = [bool]$timerState
        TimerUnitFile  = if ($timerState) { $unitFile } else { $null }
        TimerEnabled   = $timerState
    }
}

<#
    .SYNOPSIS
    Installs a crontab entry that drains the queue on a schedule.

    .DESCRIPTION
    Writes a managed block into the current user's crontab, replacing any block this
    module wrote before. Nothing outside the markers is touched, and the whole install is
    abandoned if the existing crontab cannot be read, rather than overwriting it.

    Because cron runs with a minimal environment, the entry uses absolute paths and sets
    PATH, HOME and CLAUDE_CRON_HOME itself.

    Cron only fires while the machine is awake, and it has no session bus, so
    notify-send will not reach the desktop from here: see the README, and prefer
    Install-ClaudeCronTimer if either of those matters.

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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Cron = '*/10 * * * *',

        [Parameter(Mandatory = $false)]
        [string]$Path = $env:PATH
    )
    if ($IsWindows) { throw 'Install-ClaudeCronSchedule is for Linux and macOS. On Windows use Register-ScheduledTask with the command from Get-ClaudeCronDrainCommand.' }
    [void](ConvertFrom-ClaudeCronExpression -Expression $Cron)

    # An environment line runs to the end of the line, so a newline in one of these would
    # turn the rest of the value into its own crontab entry.
    foreach ($pair in @(@('PATH', $Path), @('HOME', $HOME), @('CLAUDE_CRON_HOME', (Get-ClaudeCronRoot)))) {
        if ($pair[1] -match '[\r\n]') { throw "$($pair[0]) contains a line break and cannot be written to a crontab." }
    }

    $drain = Get-ClaudeCronDrainCommand
    $cronLog = Join-Path (Get-ClaudeCronPath).Logs 'cron.log'
    $entry = ConvertTo-ClaudeCronCommandField -Command "$Cron $($drain.CommandLine) >> $cronLog 2>&1"

    $existing = Read-ClaudeCronCrontab
    $kept = [System.Collections.Generic.List[string]]::new()
    $inBlock = $false
    foreach ($line in $existing) {
        if ($line -eq $script:ClaudeCronCronBegin) { $inBlock = $true; continue }
        if ($line -eq $script:ClaudeCronCronEnd) { $inBlock = $false; continue }
        if (-not $inBlock) { $kept.Add($line) }
    }
    $preserved = $kept.Count
    $kept.Add($script:ClaudeCronCronBegin)
    $kept.Add('SHELL=/bin/sh')
    $kept.Add("HOME=$HOME")
    $kept.Add("PATH=$Path")
    $kept.Add("CLAUDE_CRON_HOME=$($drain.Root)")
    $kept.Add($entry)
    $kept.Add($script:ClaudeCronCronEnd)
    $content = ($kept -join "`n") + "`n"

    if (-not $PSCmdlet.ShouldProcess('crontab', "Install entry: $entry")) {
        Write-Information $content -InformationAction Continue
        return
    }
    Write-ClaudeCronCrontab -Content $content
    Write-ClaudeCronLog -Level 'INFO' -Message "Installed crontab entry: $Cron ($preserved existing line(s) preserved)."
    return Get-ClaudeCronSchedule
}

<#
    .SYNOPSIS
    Removes the crontab block written by Install-ClaudeCronSchedule.

    .EXAMPLE
    Uninstall-ClaudeCronSchedule
#>
function Uninstall-ClaudeCronSchedule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param ()
    if (-not (Get-Command -Name 'crontab' -CommandType Application -ErrorAction SilentlyContinue)) { return }
    $existing = Read-ClaudeCronCrontab
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
    Write-ClaudeCronCrontab -Content (($kept -join "`n") + "`n")
    Write-ClaudeCronLog -Level 'INFO' -Message "Removed the crontab entry ($($kept.Count) other line(s) kept)."
}

<#
    .SYNOPSIS
    Installs a systemd user service and timer that drain the queue.

    .DESCRIPTION
    A better fit than cron when the machine sleeps: with Persistent=true the timer fires
    as soon as the machine wakes if the window was missed. It also runs inside the login
    session, so notify-send can reach the desktop. Run
    'loginctl enable-linger $env:USER' once if you want it to run without being logged in.

    .PARAMETER OnCalendar
    A systemd calendar expression. Defaults to every 10 minutes.

    .PARAMETER NoStart
    Write and enable the units without starting the timer now.

    .EXAMPLE
    Install-ClaudeCronTimer -OnCalendar '*:0/15'
#>
function Install-ClaudeCronTimer {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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

    # systemd reads % as the start of a specifier, so a literal one has to be doubled.
    $unitPath = $env:PATH.Replace('%', '%%')
    $unitRoot = ([string]$drain.Root).Replace('%', '%%')

    # TimeoutStartSec matters: a Type=oneshot service is killed at DefaultTimeoutStartSec,
    # 90 seconds, which is far shorter than a Claude run and far shorter than the module's
    # own JobTimeoutMinutes. The queue enforces its own timeout, so systemd should not.
    $service = @"
[Unit]
Description=Drain the ClaudeCron queue

[Service]
Type=oneshot
WorkingDirectory=$HOME
Environment=PATH=$unitPath
Environment=CLAUDE_CRON_HOME=$unitRoot
TimeoutStartSec=infinity
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
    Set-ClaudeCronFileContent -Path $servicePath -Value $service
    Set-ClaudeCronFileContent -Path $timerPath -Value $timer
    & systemctl --user daemon-reload
    if ($NoStart) {
        & systemctl --user enable "$name.timer"
    }
    else {
        & systemctl --user enable --now "$name.timer"
    }
    if ($LASTEXITCODE -ne 0) { throw "systemctl could not enable '$name.timer' (exit $LASTEXITCODE)." }
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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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

