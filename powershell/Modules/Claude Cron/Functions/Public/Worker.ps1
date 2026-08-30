<#
    .SYNOPSIS
    Runs every job that is currently due, one at a time.

    .DESCRIPTION
    This is the entry point cron, a systemd timer or the long running worker all call.
    Jobs run in priority order, oldest first within a priority. A job that fails because
    the AI quota is gone is put straight back on the queue, the whole queue is paused
    until the reset time reported by the CLI, and the drain returns without touching the
    remaining jobs. Any other failure counts against MaxAttempts before the job is
    marked Failed. A prompt job that fails because the CLI is signed out also keeps its
    budget and stops the drain, but sets no pause: there is no reset to wait for, so the
    next drain tries again in case the login has been fixed.

    Repeating jobs (-Every or -Cron) are rescheduled after each run; one-shot jobs are
    marked Done and kept until Clear-ClaudeCronQueue removes them.

    .PARAMETER Limit
    Stop after this many jobs. 0, the default, means drain everything that is due.

    .PARAMETER Force
    Run even while the queue is paused by a quota block.

    .PARAMETER Identity
    Run one specific job now, whatever its schedule says.

    .EXAMPLE
    Invoke-ClaudeCronQueue

    .EXAMPLE
    Invoke-ClaudeCronQueue -Identity svg-tests -Force
#>
function Invoke-ClaudeCronQueue {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Limit = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string]$Identity
    )
    if (-not (Enter-ClaudeCronLock)) {
        Write-ClaudeCronLog -Level 'WARN' -Message 'Another worker holds the lock; skipping this drain.'
        return
    }
    try {
        $state = Read-ClaudeCronState
        $blockedUntil = ConvertFrom-ClaudeCronTimestamp $state.BlockedUntil
        if ($blockedUntil -and $blockedUntil -gt (Get-Date) -and -not $Force) {
            Write-ClaudeCronLog -Level 'INFO' -Message "Queue paused until $($blockedUntil.ToString('yyyy-MM-dd HH:mm')) ($($state.BlockedBy))."
            return
        }
        if ($blockedUntil -and $blockedUntil -le (Get-Date)) {
            Write-ClaudeCronLog -Level 'INFO' -Message 'Quota window has reset; resuming the queue.'
            $state.BlockedUntil = $null
            $state.BlockedBy = $null
            Write-ClaudeCronState -State $state | Out-Null
        }

        $jobs = if ($Identity) { @(Resolve-ClaudeCronJob -Identity $Identity) } else { @(Get-ClaudeCronJob -Due) }
        if ($jobs.Count -eq 0) {
            Write-ClaudeCronLog -Level 'INFO' -Message 'Nothing due.'
            return
        }

        $ran = 0
        foreach ($job in $jobs) {
            if ($Limit -gt 0 -and $ran -ge $Limit) { break }
            if (-not $PSCmdlet.ShouldProcess("$($job.Id) ($($job.Name))", 'Run job')) { continue }

            $result = Invoke-ClaudeCronJobRun -Job $job
            $ran++
            if ($result.QuotaBlocked) {
                Write-ClaudeCronLog -Level 'WARN' -Message 'Stopping this drain: the AI quota is exhausted.'
                break
            }
            if ($result.AuthBlocked) {
                Write-ClaudeCronLog -Level 'WARN' -Message 'Stopping this drain: the Claude CLI is signed out.'
                break
            }
        }

        $state = Read-ClaudeCronState
        $state.LastRunAt = ConvertTo-ClaudeCronTimestamp (Get-Date)
        Write-ClaudeCronState -State $state | Out-Null
    }
    finally {
        Exit-ClaudeCronLock
    }
}

<#
    .SYNOPSIS
    Runs a single job and applies the outcome to its job file.

    .DESCRIPTION
    Returns an object with QuotaBlocked so the caller knows whether to abandon the drain.
#>
function Invoke-ClaudeCronJobRun {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Job
    )
    $config = Read-ClaudeCronConfig
    $started = Get-Date

    $Job.Status = 'Running'
    $Job.LastRunAt = ConvertTo-ClaudeCronTimestamp $started
    Write-ClaudeCronJob -Job $Job | Out-Null
    Write-ClaudeCronLog -Level 'INFO' -Message "Running $($Job.Type.ToLower()) job $($Job.Id) ($($Job.Name))."

    $invocation = Resolve-ClaudeCronInvocation -Job $Job
    $run = Invoke-ClaudeCronProcess -FilePath $invocation.FilePath `
        -Arguments $invocation.Arguments `
        -WorkingDirectory $Job.WorkingDirectory `
        -LogFile $Job.LogFile `
        -TimeoutMinutes ([int]$config.JobTimeoutMinutes)

    $Job.LastExitCode = $run.ExitCode
    $Job.LastDurationSeconds = $run.DurationSeconds

    $quota = if ($Job.Type -eq 'Prompt') {
        Test-ClaudeCronQuotaFailure -Output $run.Output -ExitCode $run.ExitCode
    }
    else {
        [pscustomobject]@{ IsQuota = $false; ResetsAt = $null; MatchedText = $null }
    }

    if ($quota.IsQuota) {
        # The job did not really get a turn, so it keeps its attempt budget.
        $Job.Status = 'Pending'
        $Job.LastError = "Quota exhausted: $($quota.MatchedText)"
        Write-ClaudeCronJob -Job $Job | Out-Null

        $state = Read-ClaudeCronState
        $state.BlockedUntil = ConvertTo-ClaudeCronTimestamp $quota.ResetsAt
        $state.BlockedBy = $Job.Id
        $state.BlockedAt = ConvertTo-ClaudeCronTimestamp (Get-Date)
        Write-ClaudeCronState -State $state | Out-Null

        Write-ClaudeCronLog -Level 'WARN' -Message "Quota exhausted on $($Job.Id); queue paused until $($quota.ResetsAt.ToString('yyyy-MM-dd HH:mm'))."
        Send-ClaudeCronNotification -Title 'Claude Cron paused' -Message "Quota exhausted. Resuming after $($quota.ResetsAt.ToString('HH:mm'))."
        return [pscustomobject]@{ Job = $Job; QuotaBlocked = $true; AuthBlocked = $false; Succeeded = $false }
    }

    if ($Job.Type -eq 'Prompt') {
        $auth = Test-ClaudeCronAuthFailure -Output $run.Output -ExitCode $run.ExitCode
        if ($auth.IsAuth) {
            # Nothing will run until someone signs in, so the job keeps its retry budget.
            $Job.Status = 'Pending'
            $Job.LastError = "Not signed in: $($auth.MatchedText)"
            Write-ClaudeCronJob -Job $Job | Out-Null
            Write-ClaudeCronLog -Level 'WARN' -Message "The Claude CLI is not signed in ($($auth.MatchedText)). Run 'claude' to log in; the queue is untouched and will retry."
            Send-ClaudeCronNotification -Title 'Claude Cron blocked' -Message 'The Claude CLI is signed out. Run claude to log in.'
            return [pscustomobject]@{ Job = $Job; QuotaBlocked = $false; AuthBlocked = $true; Succeeded = $false }
        }
    }

    if ($run.ExitCode -eq 0) {
        $Job.RunCount = [int]$Job.RunCount + 1
        $Job.Attempts = 0
        $Job.LastError = $null
        $next = Get-ClaudeCronFollowUp -Job $Job -From (Get-Date)
        $retired = $next -and $Job.MaxRuns -gt 0 -and $Job.RunCount -ge $Job.MaxRuns
        if ($next -and -not $retired) {
            $Job.Status = 'Pending'
            $Job.RunAfter = ConvertTo-ClaudeCronTimestamp $next
            Write-ClaudeCronLog -Level 'INFO' -Message "Job $($Job.Id) done in $($run.DurationSeconds)s; next run $($next.ToString('yyyy-MM-dd HH:mm'))."
        }
        else {
            $Job.Status = 'Done'
            Write-ClaudeCronLog -Level 'INFO' -Message "Job $($Job.Id) done in $($run.DurationSeconds)s."
            Write-ClaudeCronHistory -Job $Job
        }
        Write-ClaudeCronJob -Job $Job | Out-Null
        Send-ClaudeCronNotification -Title 'Claude Cron finished' -Message "$($Job.Name) finished with exit 0."
        return [pscustomobject]@{ Job = $Job; QuotaBlocked = $false; AuthBlocked = $false; Succeeded = $true }
    }

    $Job.Attempts = [int]$Job.Attempts + 1
    $tail = ($run.Output -split "`n" | Select-Object -Last 5) -join ' '
    $Job.LastError = "Exit $($run.ExitCode): $tail"
    if ($Job.Attempts -ge [int]$Job.MaxAttempts) {
        $Job.Status = 'Failed'
        Write-ClaudeCronLog -Level 'WARN' -Message "Job $($Job.Id) failed after $($Job.Attempts) attempt(s); see $($Job.LogFile)."
        Write-ClaudeCronHistory -Job $Job
        Send-ClaudeCronNotification -Title 'Claude Cron failed' -Message "$($Job.Name) failed with exit $($run.ExitCode)."
    }
    else {
        # Back off a little so a transient failure is not retried in a tight loop.
        $Job.Status = 'Pending'
        $Job.RunAfter = ConvertTo-ClaudeCronTimestamp (Get-Date).AddMinutes(5 * $Job.Attempts)
        Write-ClaudeCronLog -Level 'WARN' -Message "Job $($Job.Id) exited $($run.ExitCode); retry $($Job.Attempts)/$($Job.MaxAttempts) queued."
    }
    Write-ClaudeCronJob -Job $Job | Out-Null
    return [pscustomobject]@{ Job = $Job; QuotaBlocked = $false; AuthBlocked = $false; Succeeded = $false }
}

<#
    .SYNOPSIS
    Drains the queue on a loop, in the foreground, until stopped.

    .DESCRIPTION
    An alternative to cron for a machine that stays logged in: run this in a spare
    terminal or under a systemd user service and it polls the queue forever. While a
    quota block is in force it sleeps until a minute past the reset time instead of
    polling pointlessly.

    .PARAMETER PollSeconds
    Seconds between drains. Defaults to the configured PollSeconds.

    .PARAMETER MaxIterations
    Stop after this many loops. 0, the default, runs until Ctrl+C.

    .EXAMPLE
    Start-ClaudeCronWorker -PollSeconds 120
#>
function Start-ClaudeCronWorker {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'A polling loop the user starts deliberately; each drain it performs declares ShouldProcess.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$PollSeconds = 0,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 0
    )
    $config = Read-ClaudeCronConfig
    $interval = if ($PollSeconds -gt 0) { $PollSeconds } else { [int]$config.PollSeconds }
    Write-ClaudeCronLog -Level 'INFO' -Message "Worker started (pid $PID, polling every ${interval}s). Ctrl+C to stop."

    $iteration = 0
    try {
        while ($true) {
            $iteration++
            try {
                Invoke-ClaudeCronQueue
            }
            catch {
                Write-ClaudeCronLog -Level 'ERROR' -Message "Drain failed: $($_.Exception.Message)"
            }

            if ($MaxIterations -gt 0 -and $iteration -ge $MaxIterations) { break }

            $sleepSeconds = $interval
            $blockedUntil = ConvertFrom-ClaudeCronTimestamp (Read-ClaudeCronState).BlockedUntil
            if ($blockedUntil -and $blockedUntil -gt (Get-Date)) {
                # Wake a minute after the reset so the first attempt lands inside the new window.
                $wait = [int]($blockedUntil.AddMinutes(1) - (Get-Date)).TotalSeconds
                if ($wait -gt $sleepSeconds) {
                    $sleepSeconds = $wait
                    Write-ClaudeCronLog -Level 'INFO' -Message "Sleeping until $($blockedUntil.AddMinutes(1).ToString('yyyy-MM-dd HH:mm')) for the quota reset."
                }
            }
            Start-Sleep -Seconds $sleepSeconds
        }
    }
    finally {
        Write-ClaudeCronLog -Level 'INFO' -Message "Worker stopped (pid $PID)."
    }
}

<#
    .SYNOPSIS
    Summarises the queue, the quota block and the schedule installation.

    .EXAMPLE
    Get-ClaudeCronStatus
#>
function Get-ClaudeCronStatus {
    [CmdletBinding()]
    param ()
    $paths = Get-ClaudeCronPath
    $state = Read-ClaudeCronState
    $jobs = @(Read-ClaudeCronJob)
    $blockedUntil = ConvertFrom-ClaudeCronTimestamp $state.BlockedUntil
    $next = @($jobs | Where-Object { $_.Status -eq 'Pending' } | ForEach-Object {
            $when = ConvertFrom-ClaudeCronTimestamp $_.RunAfter
            if ($when) { $when } else { Get-Date }
        } | Sort-Object | Select-Object -First 1)

    $status = [pscustomobject]@{
        Root         = $paths.Root
        Pending      = @($jobs | Where-Object { $_.Status -eq 'Pending' }).Count
        Running      = @($jobs | Where-Object { $_.Status -eq 'Running' }).Count
        Done         = @($jobs | Where-Object { $_.Status -eq 'Done' }).Count
        Failed       = @($jobs | Where-Object { $_.Status -eq 'Failed' }).Count
        Disabled     = @($jobs | Where-Object { $_.Status -eq 'Disabled' }).Count
        QuotaBlocked = [bool]($blockedUntil -and $blockedUntil -gt (Get-Date))
        BlockedUntil = $blockedUntil
        NextRunAt    = if ($next.Count -gt 0) { $next[0] } else { $null }
        LastDrainAt  = ConvertFrom-ClaudeCronTimestamp $state.LastRunAt
        WorkerPid    = if (Test-Path -LiteralPath $paths.Lock) { (Get-Content -LiteralPath $paths.Lock -Raw).Trim() } else { $null }
        Schedule     = (Get-ClaudeCronSchedule)
    }
    $status.PSObject.TypeNames.Insert(0, 'ClaudeCron.Status')
    return $status
}
