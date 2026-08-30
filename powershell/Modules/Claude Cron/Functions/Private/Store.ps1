<#
    .SYNOPSIS
    Resolves the root directory that holds configuration, the queue and the logs.
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
    The settings applied when no config file exists yet.
#>
function Get-ClaudeCronDefaultConfig {
    [CmdletBinding()]
    param ()
    return [ordered]@{
        ClaudeCommand      = 'claude'
        DefaultClaudeArgs  = @('--print', '--permission-mode', 'acceptEdits')
        DefaultModel       = ''
        DefaultWorkingDirectory = $HOME
        PollSeconds        = 300
        QuotaResetHours    = 5
        MaxAttempts        = 3
        JobTimeoutMinutes  = 60
        NotifyCommand      = ''
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
        $saved = Get-Content -LiteralPath $paths.Config -Raw | ConvertFrom-Json
        foreach ($key in @($config.Keys)) {
            $value = $saved.PSObject.Properties[$key]
            if ($null -ne $value) { $config[$key] = $value.Value }
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
    $Config | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $paths.Config -Encoding utf8
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
#>
function New-ClaudeCronId {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Generates a string; changes nothing.')]
    [CmdletBinding()]
    param ()
    $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
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
    $Job | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Get-ClaudeCronJobPath -Id $Job.Id) -Encoding utf8
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
    Get-ChildItem -LiteralPath $queue -Filter '*.json' -File | Sort-Object Name | ForEach-Object {
        try {
            $job = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
            $job.PSObject.TypeNames.Insert(0, 'ClaudeCron.Job')
            $job
        }
        catch {
            Write-ClaudeCronLog -Level 'WARN' -Message "Skipping unreadable job file '$($_.Name)': $($_.Exception.Message)"
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
        $saved = Get-Content -LiteralPath $paths.State -Raw | ConvertFrom-Json
        foreach ($key in @($state.Keys)) {
            $value = $saved.PSObject.Properties[$key]
            if ($null -ne $value) { $state[$key] = $value.Value }
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
    $State | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $paths.State -Encoding utf8
    return $State
}

<#
    .SYNOPSIS
    Appends a finished run to history.jsonl so completed work survives job deletion.
#>
function Write-ClaudeCronHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Job
    )
    $paths = Get-ClaudeCronPath
    $entry = [ordered]@{
        Id           = $Job.Id
        Name         = $Job.Name
        Type         = $Job.Type
        Status       = $Job.Status
        FinishedAt   = ConvertTo-ClaudeCronTimestamp (Get-Date)
        DurationSeconds = $Job.LastDurationSeconds
        ExitCode     = $Job.LastExitCode
        LogFile      = $Job.LogFile
    }
    ($entry | ConvertTo-Json -Depth 5 -Compress) | Add-Content -LiteralPath $paths.History -Encoding utf8
}
