<#
    .SYNOPSIS
    Queues a Claude prompt to run later, unattended.

    .DESCRIPTION
    The prompt is stored as a job file and picked up by Invoke-ClaudeCronQueue. With no
    scheduling switches the job runs on the next drain, which is the behaviour you want
    when the AI quota has just run out: queue the work now, let the worker send it the
    moment the quota is back.

    .PARAMETER Prompt
    The text handed to the Claude CLI.

    .PARAMETER Name
    A friendly label. Defaults to the first few words of the prompt.

    .PARAMETER At
    Hold the job until this moment. Accepts anything Get-Date understands, such as
    '18:00' or '2026-09-01 07:30'.

    .PARAMETER Every
    Repeat on a fixed interval after each run: 30m, 2h, 2h30m, 1d.

    .PARAMETER Cron
    Repeat on a five field cron expression, or a macro such as @daily.

    .PARAMETER WorkingDirectory
    Directory the CLI is launched in. Defaults to the configured working directory.

    .PARAMETER Model
    Model name passed through as --model.

    .PARAMETER ClaudeArgs
    Replaces the configured default CLI arguments for this job only.

    .PARAMETER MaxRuns
    Retire a repeating job after this many successful runs.

    .PARAMETER Priority
    Higher numbers are drained first. Ties fall back to creation order.

    .EXAMPLE
    Add-ClaudeCronPrompt -Prompt 'Add tests for the SVG converter' -Name svg-tests

    Queues work to run the next time quota is available.

    .EXAMPLE
    Add-ClaudeCronPrompt -Prompt 'Summarise yesterday''s commits' -Cron '0 8 * * 1-5'

    Runs every weekday at 08:00.
#>
function Add-ClaudeCronPrompt {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Once')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Prompt,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [datetime]$At,

        [Parameter(Mandatory = $true, ParameterSetName = 'Interval')]
        [string]$Every,

        [Parameter(Mandatory = $true, ParameterSetName = 'Cron')]
        [string]$Cron,

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [string]$Model,

        [Parameter(Mandatory = $false)]
        [string[]]$ClaudeArgs,

        [Parameter(Mandatory = $false)]
        [int]$MaxRuns = 0,

        [Parameter(Mandatory = $false)]
        [int]$Priority = 0
    )
    process {
        $parameters = @{
            Type             = 'Prompt'
            Payload          = $Prompt
            Name             = $Name
            MaxRuns          = $MaxRuns
            Priority         = $Priority
            WorkingDirectory = $WorkingDirectory
            Model            = $Model
            ClaudeArgs       = $ClaudeArgs
        }
        if ($PSBoundParameters.ContainsKey('At')) { $parameters.At = $At }
        if ($PSBoundParameters.ContainsKey('Every')) { $parameters.Every = $Every }
        if ($PSBoundParameters.ContainsKey('Cron')) { $parameters.Cron = $Cron }
        if ($PSCmdlet.ShouldProcess($Prompt, 'Queue Claude prompt')) {
            New-ClaudeCronJobObject @parameters
        }
    }
}

<#
    .SYNOPSIS
    Queues a shell or PowerShell command to run at a time or on an interval.

    .DESCRIPTION
    Same scheduling model as Add-ClaudeCronPrompt, but the payload is a command instead
    of a prompt. Useful for the chores around the prompts: syncing a repo before the
    queue drains, or pushing the results afterwards.

    .PARAMETER Command
    The command line to run.

    .PARAMETER Shell
    'pwsh' (default) runs the command under PowerShell; 'sh' runs it under /bin/sh.

    .EXAMPLE
    Add-ClaudeCronCommand -Command 'git -C ~/src/app pull --ff-only' -Every 1h
#>
function Add-ClaudeCronCommand {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Once')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('pwsh', 'sh')]
        [string]$Shell = 'pwsh',

        [Parameter(Mandatory = $false)]
        [datetime]$At,

        [Parameter(Mandatory = $true, ParameterSetName = 'Interval')]
        [string]$Every,

        [Parameter(Mandatory = $true, ParameterSetName = 'Cron')]
        [string]$Cron,

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [int]$MaxRuns = 0,

        [Parameter(Mandatory = $false)]
        [int]$Priority = 0
    )
    process {
        $parameters = @{
            Type             = 'Command'
            Payload          = $Command
            Name             = $Name
            Shell            = $Shell
            MaxRuns          = $MaxRuns
            Priority         = $Priority
            WorkingDirectory = $WorkingDirectory
        }
        if ($PSBoundParameters.ContainsKey('At')) { $parameters.At = $At }
        if ($PSBoundParameters.ContainsKey('Every')) { $parameters.Every = $Every }
        if ($PSBoundParameters.ContainsKey('Cron')) { $parameters.Cron = $Cron }
        if ($PSCmdlet.ShouldProcess($Command, 'Queue command')) {
            New-ClaudeCronJobObject @parameters
        }
    }
}

<#
    .SYNOPSIS
    Creates and persists the job file shared by the two Add- commands.
#>
function New-ClaudeCronJobObject {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal helper; the exported command that calls it declares ShouldProcess.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Prompt', 'Command')]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Payload,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Shell = 'pwsh',

        [Parameter(Mandatory = $false)]
        [datetime]$At,

        [Parameter(Mandatory = $false)]
        [string]$Every,

        [Parameter(Mandatory = $false)]
        [string]$Cron,

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [string]$Model,

        [Parameter(Mandatory = $false)]
        [string[]]$ClaudeArgs,

        [Parameter(Mandatory = $false)]
        [int]$MaxRuns = 0,

        [Parameter(Mandatory = $false)]
        [int]$Priority = 0
    )
    $config = Read-ClaudeCronConfig
    $id = New-ClaudeCronId

    $intervalSeconds = $null
    if ($Every) { $intervalSeconds = [int](ConvertTo-ClaudeCronTimeSpan -Interval $Every).TotalSeconds }
    if ($Cron) { [void](ConvertFrom-ClaudeCronExpression -Expression $Cron) }

    $runAfter = if ($PSBoundParameters.ContainsKey('At')) {
        $At
    }
    elseif ($Cron) {
        Get-ClaudeCronNextRun -Expression $Cron
    }
    else {
        $null
    }

    $label = if ($Name) {
        $Name
    }
    else {
        $words = ($Payload -split '\s+' | Select-Object -First 6) -join ' '
        if ($words.Length -gt 48) { $words.Substring(0, 48) } else { $words }
    }

    $directory = if ($WorkingDirectory) { $WorkingDirectory } else { [string]$config.DefaultWorkingDirectory }
    if (-not (Test-Path -LiteralPath $directory)) {
        throw "Working directory '$directory' does not exist."
    }

    $job = [pscustomobject][ordered]@{
        Id                  = $id
        Name                = $label
        Type                = $Type
        Status              = 'Pending'
        Prompt              = if ($Type -eq 'Prompt') { $Payload } else { $null }
        Command             = if ($Type -eq 'Command') { $Payload } else { $null }
        Shell               = $Shell
        WorkingDirectory    = (Resolve-Path -LiteralPath $directory).Path
        Model               = $Model
        ClaudeArgs          = $ClaudeArgs
        RunAfter            = ConvertTo-ClaudeCronTimestamp $runAfter
        IntervalSeconds     = $intervalSeconds
        Cron                = $Cron
        Priority            = $Priority
        MaxRuns             = $MaxRuns
        RunCount            = 0
        Attempts            = 0
        MaxAttempts         = [int]$config.MaxAttempts
        CreatedAt           = ConvertTo-ClaudeCronTimestamp (Get-Date)
        UpdatedAt           = $null
        LastRunAt           = $null
        LastExitCode        = $null
        LastError           = $null
        LastDurationSeconds = $null
        LogFile             = (Join-Path (Get-ClaudeCronPath).Logs "$id.log")
    }
    $job.PSObject.TypeNames.Insert(0, 'ClaudeCron.Job')
    Write-ClaudeCronJob -Job $job | Out-Null
    Write-ClaudeCronLog -Level 'INFO' -Message "Queued $Type job $id ($label)."
    return $job
}

<#
    .SYNOPSIS
    Lists queued jobs.

    .PARAMETER Identity
    An id, an id prefix, or a name. Wildcards are allowed in the name.

    .PARAMETER Status
    Filter by state: Pending, Running, Done, Failed or Disabled.

    .PARAMETER Due
    Return only jobs that are eligible to run right now.

    .EXAMPLE
    Get-ClaudeCronJob -Status Pending | Format-Table Id, Name, RunAfter

    .EXAMPLE
    Get-ClaudeCronJob svg-tests
#>
function Get-ClaudeCronJob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id', 'Name')]
        [string]$Identity,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Pending', 'Running', 'Done', 'Failed', 'Disabled')]
        [string[]]$Status,

        [Parameter(Mandatory = $false)]
        [switch]$Due
    )
    process {
        $now = Get-Date
        Read-ClaudeCronJob | Where-Object {
            $keep = $true
            if ($Identity -and -not ($_.Id -like "$Identity*" -or $_.Name -like $Identity)) { $keep = $false }
            if ($Status -and $Status -notcontains $_.Status) { $keep = $false }
            if ($Due) {
                if ($_.Status -ne 'Pending') { $keep = $false }
                $runAfter = ConvertFrom-ClaudeCronTimestamp $_.RunAfter
                if ($runAfter -and $runAfter -gt $now) { $keep = $false }
            }
            $keep
        } | Sort-Object -Property @{ Expression = 'Priority'; Descending = $true }, @{ Expression = 'CreatedAt' }
    }
}

<#
    .SYNOPSIS
    Resolves a partial id or name to exactly one job, or throws.
#>
function Resolve-ClaudeCronJob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )
    $found = @(Read-ClaudeCronJob | Where-Object { $_.Id -eq $Identity -or $_.Id -like "$Identity*" -or $_.Name -eq $Identity })
    if ($found.Count -eq 0) { throw "No job matches '$Identity'." }
    if ($found.Count -gt 1) {
        throw "'$Identity' matches $($found.Count) jobs: $(($found.Id) -join ', ')."
    }
    return $found[0]
}

<#
    .SYNOPSIS
    Removes queued jobs.

    .PARAMETER Identity
    A job id, a unique id prefix, or an exact job name.

    .PARAMETER KeepLog
    Leave the job's log file on disk.

    .EXAMPLE
    Remove-ClaudeCronJob 20260830-101500-a1b2
#>
function Remove-ClaudeCronJob {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string[]]$Identity,

        [Parameter(Mandatory = $false)]
        [switch]$KeepLog
    )
    process {
        foreach ($item in $Identity) {
            $job = Resolve-ClaudeCronJob -Identity $item
            if (-not $PSCmdlet.ShouldProcess("$($job.Id) ($($job.Name))", 'Remove job')) { continue }
            Remove-Item -LiteralPath (Get-ClaudeCronJobPath -Id $job.Id) -Force
            if (-not $KeepLog -and $job.LogFile -and (Test-Path -LiteralPath $job.LogFile)) {
                Remove-Item -LiteralPath $job.LogFile -Force
            }
            Write-ClaudeCronLog -Level 'INFO' -Message "Removed job $($job.Id) ($($job.Name))."
        }
    }
}

<#
    .SYNOPSIS
    Changes a queued job in place.

    .DESCRIPTION
    Use this to push a job back, change its schedule, re-enable a job that hit its retry
    limit, or reset a Failed job to Pending so the next drain tries it again.

    .PARAMETER Enable
    Set the job back to Pending and clear the attempt counter.

    .PARAMETER Disable
    Mark the job Disabled so drains skip it.

    .EXAMPLE
    Set-ClaudeCronJob svg-tests -At '06:00' -Priority 10
#>
function Set-ClaudeCronJob {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$Identity,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [datetime]$At,

        [Parameter(Mandatory = $false)]
        [string]$Every,

        [Parameter(Mandatory = $false)]
        [string]$Cron,

        [Parameter(Mandatory = $false)]
        [string]$Prompt,

        [Parameter(Mandatory = $false)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [string]$Model,

        [Parameter(Mandatory = $false)]
        [int]$Priority,

        [Parameter(Mandatory = $false)]
        [switch]$Enable,

        [Parameter(Mandatory = $false)]
        [switch]$Disable
    )
    process {
        $job = Resolve-ClaudeCronJob -Identity $Identity
        if (-not $PSCmdlet.ShouldProcess("$($job.Id) ($($job.Name))", 'Update job')) { return }

        if ($PSBoundParameters.ContainsKey('Name')) { $job.Name = $Name }
        if ($PSBoundParameters.ContainsKey('Prompt')) { $job.Prompt = $Prompt }
        if ($PSBoundParameters.ContainsKey('Command')) { $job.Command = $Command }
        if ($PSBoundParameters.ContainsKey('Model')) { $job.Model = $Model }
        if ($PSBoundParameters.ContainsKey('Priority')) { $job.Priority = $Priority }
        if ($PSBoundParameters.ContainsKey('WorkingDirectory')) {
            if (-not (Test-Path -LiteralPath $WorkingDirectory)) { throw "Working directory '$WorkingDirectory' does not exist." }
            $job.WorkingDirectory = (Resolve-Path -LiteralPath $WorkingDirectory).Path
        }
        if ($PSBoundParameters.ContainsKey('Every')) {
            $job.IntervalSeconds = [int](ConvertTo-ClaudeCronTimeSpan -Interval $Every).TotalSeconds
            $job.Cron = $null
        }
        if ($PSBoundParameters.ContainsKey('Cron')) {
            [void](ConvertFrom-ClaudeCronExpression -Expression $Cron)
            $job.Cron = $Cron
            $job.IntervalSeconds = $null
            $job.RunAfter = ConvertTo-ClaudeCronTimestamp (Get-ClaudeCronNextRun -Expression $Cron)
        }
        if ($PSBoundParameters.ContainsKey('At')) { $job.RunAfter = ConvertTo-ClaudeCronTimestamp $At }
        if ($Enable) {
            $job.Status = 'Pending'
            $job.Attempts = 0
            $job.LastError = $null
        }
        if ($Disable) { $job.Status = 'Disabled' }

        Write-ClaudeCronJob -Job $job
    }
}

<#
    .SYNOPSIS
    Empties the queue.

    .PARAMETER Status
    Only remove jobs in these states. Defaults to finished work (Done and Failed).

    .PARAMETER All
    Remove every job regardless of state.

    .EXAMPLE
    Clear-ClaudeCronQueue

    Clears out completed and failed jobs, leaving pending work alone.
#>
function Clear-ClaudeCronQueue {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Pending', 'Running', 'Done', 'Failed', 'Disabled')]
        [string[]]$Status = @('Done', 'Failed'),

        [Parameter(Mandatory = $false)]
        [switch]$All
    )
    $targets = if ($All) { @(Read-ClaudeCronJob) } else { @(Read-ClaudeCronJob | Where-Object { $Status -contains $_.Status }) }
    if ($targets.Count -eq 0) {
        Write-ClaudeCronLog -Level 'INFO' -Message 'Nothing to clear.'
        return
    }
    if (-not $PSCmdlet.ShouldProcess("$($targets.Count) job(s)", 'Clear queue')) { return }
    foreach ($job in $targets) {
        Remove-Item -LiteralPath (Get-ClaudeCronJobPath -Id $job.Id) -Force -ErrorAction SilentlyContinue
    }
    Write-ClaudeCronLog -Level 'INFO' -Message "Cleared $($targets.Count) job(s)."
}

<#
    .SYNOPSIS
    Shows the captured output of a job's runs.

    .PARAMETER Tail
    Show only the last N lines.

    .EXAMPLE
    Get-ClaudeCronLog svg-tests -Tail 40
#>
function Get-ClaudeCronLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$Identity,

        [Parameter(Mandatory = $false)]
        [int]$Tail = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )
    process {
        $logFile = if ($Identity) {
            (Resolve-ClaudeCronJob -Identity $Identity).LogFile
        }
        else {
            Join-Path (Get-ClaudeCronPath).Logs 'claude-cron.log'
        }
        if (-not (Test-Path -LiteralPath $logFile)) {
            Write-ClaudeCronLog -Level 'WARN' -Message "No log yet at '$logFile'."
            return
        }
        $parameters = @{ LiteralPath = $logFile }
        if ($Tail -gt 0) { $parameters.Tail = $Tail }
        if ($Wait) { $parameters.Wait = $true }
        Get-Content @parameters
    }
}
