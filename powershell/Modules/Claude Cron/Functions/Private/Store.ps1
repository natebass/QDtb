<#
    .SYNOPSIS
    Resolves the root directory that holds configuration, the queue and the logs.

    .DESCRIPTION
    CLAUDE_CRON_HOME wins when it is set. Otherwise the XDG config directory is used,
    which is what an interactive shell resolves to. Note that cron and systemd do not
    inherit a shell's XDG_CONFIG_HOME: the installers bake the root resolved at install
    time into the unit they write, so the scheduler always drains the queue you can see.
#>
function Get-ClaudeCronRoot {
    [CmdletBinding()]
    param ()
    if ($env:CLAUDE_CRON_HOME) { return $env:CLAUDE_CRON_HOME }
    $base = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
    return (Join-Path $base 'claude-cron')
}

<#
    .SYNOPSIS
    Returns the well known paths used by the module, creating the folders on first use.
#>
function Get-ClaudeCronPath {
    [CmdletBinding()]
    param ()
    $root = Get-ClaudeCronRoot
    $paths = [pscustomobject]@{
        Root    = $root
        Config  = Join-Path $root 'config.json'
        State   = Join-Path $root 'state.json'
        Queue   = Join-Path $root 'queue'
        Logs    = Join-Path $root 'logs'
        Lock    = Join-Path $root 'worker.lock'
        History = Join-Path $root 'history.jsonl'
    }
    foreach ($dir in @($paths.Root, $paths.Queue, $paths.Logs)) {
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    return $paths
}

<#
    .SYNOPSIS
    Writes text to a file so a reader never sees a half written one.

    .DESCRIPTION
    Set-Content truncates before it writes, so a crash or a concurrent read in the middle
    of one leaves a truncated file behind - for a job file that means the job is silently
    dropped by Read-ClaudeCronJob. Writing a sibling temp file and renaming it into place
    is atomic on every filesystem this module runs on.
#>
function Set-ClaudeCronFileContent {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal helper; the exported command that calls it declares ShouldProcess.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )
    $temporary = "$Path.$PID.tmp"
    try {
        # No BOM, and a trailing newline so the files stay pleasant to read and diff.
        [System.IO.File]::WriteAllText($temporary, $Value + [System.Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temporary, $Path, $true)
    }
    catch {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
        throw
    }
}

<#
    .SYNOPSIS
    The settings applied when no config file exists yet.
#>
function Get-ClaudeCronDefaultConfig {
    [CmdletBinding()]
    param ()
    return [ordered]@{
        ClaudeCommand           = 'claude'
        DefaultClaudeArgs       = @('--print', '--permission-mode', 'auto')
        DefaultModel            = ''
        # ~/Desktop rather than $HOME: an unattended run can rewrite anything under
        # whichever directory it starts in, so the default is somewhere narrower than the
        # whole home directory. A machine with no Desktop folder needs
        # Set-ClaudeCronConfig -DefaultWorkingDirectory before the first job is queued.
        DefaultWorkingDirectory = (Join-Path $HOME 'Desktop')
        PollSeconds             = 300
        QuotaResetHours         = 5
        MaxAttempts             = 3
        JobTimeoutMinutes       = 60
        NotifyCommand           = ''
        MaxLogSizeMB            = 5
    }
}

<#
    .SYNOPSIS
    Reads config.json, filling in any value the file does not define.
#>
function Read-ClaudeCronConfig {
    [CmdletBinding()]
    param ()
    $paths = Get-ClaudeCronPath
    $config = Get-ClaudeCronDefaultConfig
    if (Test-Path -LiteralPath $paths.Config) {
        try {
            $saved = Get-Content -LiteralPath $paths.Config -Raw | ConvertFrom-Json
            foreach ($key in @($config.Keys)) {
                $value = $saved.PSObject.Properties[$key]
                if ($null -ne $value) { $config[$key] = $value.Value }
            }
        }
        catch {
            # A damaged config must not stop the queue: fall back to the defaults and say so.
            Write-Warning "config.json could not be read ($($_.Exception.Message)); using defaults."
        }
    }
    return [pscustomobject]$config
}

<#
    .SYNOPSIS
    Persists a configuration object back to config.json.
#>
function Write-ClaudeCronConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Config
    )
    $paths = Get-ClaudeCronPath
    Set-ClaudeCronFileContent -Path $paths.Config -Value ($Config | ConvertTo-Json -Depth 6)
    return $Config
}

<#
    .SYNOPSIS
    Converts a date to the round-trip UTC string used inside the job files.
#>
function ConvertTo-ClaudeCronTimestamp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        [object]$Date
    )
    if ($null -eq $Date) { return $null }
    return ([datetime]$Date).ToUniversalTime().ToString('o')
}

<#
    .SYNOPSIS
    Converts a stored timestamp back to a local DateTime.
#>
function ConvertFrom-ClaudeCronTimestamp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text
    )
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $parsed = [datetime]::MinValue
    $styles = [System.Globalization.DateTimeStyles]::RoundtripKind
    if ([datetime]::TryParse($Text, [cultureinfo]::InvariantCulture, $styles, [ref]$parsed)) {
        return $parsed.ToLocalTime()
    }
    return $null
}

<#
    .SYNOPSIS
    Builds a short, sortable and collision resistant job id.

    .DESCRIPTION
    The stamp is UTC so ids keep sorting in run order across a daylight saving change;
    Read-ClaudeCronJob relies on that ordering.
#>
function New-ClaudeCronId {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Generates a string; changes nothing.')]
    [CmdletBinding()]
    param ()
    $stamp = [datetime]::UtcNow.ToString('yyyyMMdd-HHmmss')
    $suffix = ([guid]::NewGuid().ToString('N')).Substring(0, 4)
    return "$stamp-$suffix"
}

<#
    .SYNOPSIS
    Returns the path of the file backing a single job.
#>
function Get-ClaudeCronJobPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id
    )
    return (Join-Path (Get-ClaudeCronPath).Queue "$Id.json")
}

<#
    .SYNOPSIS
    Writes a job object to disk.
#>
function Write-ClaudeCronJob {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal helper; the exported command that calls it declares ShouldProcess.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Job
    )
    $Job.UpdatedAt = ConvertTo-ClaudeCronTimestamp (Get-Date)
    Set-ClaudeCronFileContent -Path (Get-ClaudeCronJobPath -Id $Job.Id) -Value ($Job | ConvertTo-Json -Depth 8)
    return $Job
}

<#
    .SYNOPSIS
    Reads every job file from the queue directory, newest last.
#>
function Read-ClaudeCronJob {
    [CmdletBinding()]
    param ()
    $queue = (Get-ClaudeCronPath).Queue
    foreach ($file in (Get-ChildItem -LiteralPath $queue -Filter '*.json' -File | Sort-Object Name)) {
        try {
            $job = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            $job.PSObject.TypeNames.Insert(0, 'ClaudeCron.Job')
            $job
        }
        catch {
            # $_ here is the error record, so the file has to come from the loop variable.
            Write-ClaudeCronLog -Level 'WARN' -Message "Skipping unreadable job file '$($file.Name)': $($_.Exception.Message)"
        }
    }
}

<#
    .SYNOPSIS
    Reads the worker state file that tracks quota blocks and the last drain.
#>
function Read-ClaudeCronState {
    [CmdletBinding()]
    param ()
    $paths = Get-ClaudeCronPath
    $state = [ordered]@{
        BlockedUntil = $null
        BlockedBy    = $null
        BlockedAt    = $null
        LastRunAt    = $null
    }
    if (Test-Path -LiteralPath $paths.State) {
        try {
            $saved = Get-Content -LiteralPath $paths.State -Raw | ConvertFrom-Json
            foreach ($key in @($state.Keys)) {
                $value = $saved.PSObject.Properties[$key]
                if ($null -ne $value) { $state[$key] = $value.Value }
            }
        }
        catch {
            Write-Warning "state.json could not be read ($($_.Exception.Message)); starting from a clean state."
        }
    }
    return [pscustomobject]$state
}

<#
    .SYNOPSIS
    Persists the worker state file.
#>
function Write-ClaudeCronState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$State
    )
    $paths = Get-ClaudeCronPath
    Set-ClaudeCronFileContent -Path $paths.State -Value ($State | ConvertTo-Json -Depth 6)
    return $State
}

<#
    .SYNOPSIS
    Appends a finished run to history.jsonl so completed work survives job deletion.

    .DESCRIPTION
    Every finished run is recorded, not only the last one: a repeating job would otherwise
    leave no trace of the runs it made before it was retired or removed.
#>
function Write-ClaudeCronHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Job
    )
    $paths = Get-ClaudeCronPath
    $entry = [ordered]@{
        Id              = $Job.Id
        Name            = $Job.Name
        Type            = $Job.Type
        Status          = $Job.Status
        FinishedAt      = ConvertTo-ClaudeCronTimestamp (Get-Date)
        DurationSeconds = $Job.LastDurationSeconds
        ExitCode        = $Job.LastExitCode
        LogFile         = $Job.LogFile
    }
    try {
        ($entry | ConvertTo-Json -Depth 5 -Compress) | Add-Content -LiteralPath $paths.History -Encoding utf8
    }
    catch {
        Write-ClaudeCronLog -Level 'WARN' -Message "Could not append to history.jsonl: $($_.Exception.Message)"
    }
}
