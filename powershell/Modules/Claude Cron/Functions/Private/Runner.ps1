<#
    .SYNOPSIS
    Builds the executable and argument list for a job.

    .DESCRIPTION
    Prompt jobs call the Claude CLI in print mode; command jobs go through pwsh -Command
    or sh -c. The prompt itself is always passed as its own argument so quoting inside a
    prompt never reaches a shell.
#>
function Resolve-ClaudeCronInvocation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Job
    )
    $config = Read-ClaudeCronConfig

    if ($Job.Type -eq 'Prompt') {
        $arguments = [System.Collections.Generic.List[string]]::new()
        $baseArgs = if ($null -ne $Job.ClaudeArgs -and @($Job.ClaudeArgs).Count -gt 0) {
            @($Job.ClaudeArgs)
        }
        else {
            @($config.DefaultClaudeArgs)
        }
        foreach ($argument in $baseArgs) { $arguments.Add([string]$argument) }

        $model = if ($Job.Model) { $Job.Model } else { $config.DefaultModel }
        if ($model) {
            $arguments.Add('--model')
            $arguments.Add([string]$model)
        }
        # The prompt goes last. Only a prompt that opens with a dash needs the -- guard.
        if ([string]$Job.Prompt -match '^\s*-') { $arguments.Add('--') }
        $arguments.Add([string]$Job.Prompt)

        return [pscustomobject]@{
            FilePath  = [string]$config.ClaudeCommand
            Arguments = $arguments.ToArray()
        }
    }

    if ($Job.Shell -eq 'sh' -and -not $IsWindows) {
        return [pscustomobject]@{
            FilePath  = '/bin/sh'
            Arguments = @('-c', [string]$Job.Command)
        }
    }
    return [pscustomobject]@{
        FilePath  = Get-ClaudeCronPwshPath
        Arguments = @('-NoProfile', '-NonInteractive', '-Command', [string]$Job.Command)
    }
}

<#
    .SYNOPSIS
    Finds the pwsh executable that command jobs should run under.
#>
function Get-ClaudeCronPwshPath {
    [CmdletBinding()]
    param ()
    $current = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ($current -and (Split-Path $current -Leaf) -like 'pwsh*') { return $current }
    $command = Get-Command -Name 'pwsh' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    return 'pwsh'
}

<#
    .SYNOPSIS
    Runs one process to completion, capturing output to the job log file.

    .DESCRIPTION
    Returns the exit code, the wall clock duration and the captured text. A job that
    outruns JobTimeoutMinutes is killed and reported with exit code 124, matching the
    convention used by timeout(1).
#>
function Invoke-ClaudeCronProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $true)]
        [int]$TimeoutMinutes
    )
    $info = [System.Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $FilePath
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    $info.WorkingDirectory = $WorkingDirectory
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    # Redirected so the child gets its own stdin, which is closed below. Inheriting this
    # process's stdin makes the Claude CLI stall for seconds waiting for piped input, and
    # under cron or systemd there is no terminal to inherit in the first place.
    $info.RedirectStandardInput = $true
    $info.UseShellExecute = $false

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $info

    $started = Get-Date
    $timedOut = $false
    try {
        [void]$process.Start()
    }
    catch {
        return [pscustomobject]@{
            ExitCode        = 127
            Output          = "Failed to start '$FilePath': $($_.Exception.Message)"
            DurationSeconds = 0
            TimedOut        = $false
        }
    }

    # Signal end-of-input straight away; this is the equivalent of running with < /dev/null.
    try { $process.StandardInput.Close() } catch { Write-Debug "Could not close stdin: $($_.Exception.Message)" }

    # Read both streams asynchronously so a chatty child process cannot deadlock on a full pipe.
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    if (-not $process.WaitForExit($TimeoutMinutes * 60 * 1000)) {
        $timedOut = $true
        try { $process.Kill($true) } catch { Write-Debug "Kill failed: $($_.Exception.Message)" }
        [void]$process.WaitForExit(10000)
    }

    $stdout = try { $stdoutTask.GetAwaiter().GetResult() } catch { '' }
    $stderr = try { $stderrTask.GetAwaiter().GetResult() } catch { '' }
    $duration = ((Get-Date) - $started).TotalSeconds
    $exitCode = if ($timedOut) { 124 } else { $process.ExitCode }
    $process.Dispose()

    $output = @($stdout, $stderr) | Where-Object { $_ } | Join-String -Separator "`n"
    $header = @(
        '=' * 72
        "run     : $($started.ToString('yyyy-MM-dd HH:mm:ss'))"
        "command : $FilePath $($Arguments -join ' ')"
        "cwd     : $WorkingDirectory"
        "exit    : $exitCode$(if ($timedOut) { ' (timed out)' })"
        "seconds : $([math]::Round($duration, 1))"
        '=' * 72
    ) -join "`n"
    Add-Content -LiteralPath $LogFile -Value "$header`n$output`n" -Encoding utf8

    return [pscustomobject]@{
        ExitCode        = $exitCode
        Output          = $output
        DurationSeconds = [math]::Round($duration, 1)
        TimedOut        = $timedOut
    }
}

<#
    .SYNOPSIS
    Decides whether a failed run was the AI quota running out, and when it comes back.

    .DESCRIPTION
    The CLI emits a machine readable sentinel of the form
    "Claude AI usage limit reached|<unix seconds>". When that is present the exact reset
    time is used; otherwise a wall clock time mentioned in the message is honoured, and
    failing both, the configured QuotaResetHours is added to now.
#>
function Test-ClaudeCronQuotaFailure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Output,

        [Parameter(Mandatory = $true)]
        [int]$ExitCode
    )
    $result = [pscustomobject]@{
        IsQuota      = $false
        ResetsAt     = $null
        MatchedText  = $null
    }
    if ([string]::IsNullOrWhiteSpace($Output)) { return $result }

    # The sentinel is trusted on its own; anything softer needs a failed exit code too,
    # so a prompt that merely talks about rate limits does not pause the queue.
    $sentinel = [regex]::Match($Output, 'usage limit reached\s*\|\s*(\d{9,})', 'IgnoreCase')
    if ($sentinel.Success) {
        $result.IsQuota = $true
        $result.MatchedText = $sentinel.Value
        $result.ResetsAt = [System.DateTimeOffset]::FromUnixTimeSeconds([long]$sentinel.Groups[1].Value).LocalDateTime
        return $result
    }
    if ($ExitCode -eq 0) { return $result }

    $patterns = @(
        'usage limit reached'
        '\b5-hour limit\b'
        'weekly limit reached'
        'rate[_ -]?limit(_error)?'
        'quota (has been )?(exceeded|exhausted)'
        'out of (credits|tokens)'
        'insufficient (credit|quota|balance)'
        'too many requests'
        '\b429\b'
    )
    foreach ($pattern in $patterns) {
        $match = [regex]::Match($Output, $pattern, 'IgnoreCase')
        if (-not $match.Success) { continue }
        $result.IsQuota = $true
        $result.MatchedText = $match.Value

        # "resets at 3pm", "resets 15:00", "try again at 9:30 am"
        $clock = [regex]::Match($Output, '(?:resets?|try again|available again)[^0-9]{0,20}(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', 'IgnoreCase')
        if ($clock.Success) {
            $hour = [int]$clock.Groups[1].Value
            $minute = if ($clock.Groups[2].Success) { [int]$clock.Groups[2].Value } else { 0 }
            $meridiem = $clock.Groups[3].Value.ToLowerInvariant()
            if ($meridiem -eq 'pm' -and $hour -lt 12) { $hour += 12 }
            if ($meridiem -eq 'am' -and $hour -eq 12) { $hour = 0 }
            if ($hour -le 23 -and $minute -le 59) {
                $now = Get-Date
                $reset = $now.Date.AddHours($hour).AddMinutes($minute)
                if ($reset -le $now) { $reset = $reset.AddDays(1) }
                $result.ResetsAt = $reset
            }
        }
        if ($null -eq $result.ResetsAt) {
            $result.ResetsAt = (Get-Date).AddHours([double](Read-ClaudeCronConfig).QuotaResetHours)
        }
        return $result
    }
    return $result
}

<#
    .SYNOPSIS
    Decides whether a failed run was the CLI being logged out.

    .DESCRIPTION
    An expired login is not a transient failure and not a quota window: nothing will
    succeed until someone runs 'claude' and signs in again. The runner treats it like a
    quota block in that the job keeps its retry budget and the drain stops, but it sets
    no reset time, because there is nothing to wait for - the next drain tries again in
    case the login has been fixed by then.
#>
function Test-ClaudeCronAuthFailure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Output,

        [Parameter(Mandatory = $true)]
        [int]$ExitCode
    )
    $result = [pscustomobject]@{ IsAuth = $false; MatchedText = $null }
    if ($ExitCode -eq 0 -or [string]::IsNullOrWhiteSpace($Output)) { return $result }

    $patterns = @(
        'failed to authenticate'
        'oauth (session|token) expired'
        'authentication[_ ]error'
        'not logged in'
        'please (run )?[`"'']?claude[`"'']? to log ?in'
        'invalid api key'
        'unauthorized'
        '\b401\b'
    )
    foreach ($pattern in $patterns) {
        $match = [regex]::Match($Output, $pattern, 'IgnoreCase')
        if ($match.Success) {
            $result.IsAuth = $true
            $result.MatchedText = $match.Value
            return $result
        }
    }
    return $result
}

<#
    .SYNOPSIS
    Stops a second worker from draining the queue at the same time as this one.

    .DESCRIPTION
    A lock file holding a pid is written on entry. A lock whose process is gone is
    treated as stale and taken over, which is what happens after a reboot or a kill -9.
#>
function Enter-ClaudeCronLock {
    [CmdletBinding()]
    param ()
    $lockFile = (Get-ClaudeCronPath).Lock
    if (Test-Path -LiteralPath $lockFile) {
        $owner = (Get-Content -LiteralPath $lockFile -Raw).Trim()
        $ownerPid = 0
        if ([int]::TryParse($owner, [ref]$ownerPid) -and $ownerPid -ne $PID) {
            if (Get-Process -Id $ownerPid -ErrorAction SilentlyContinue) { return $false }
            Write-ClaudeCronLog -Level 'WARN' -Message "Removing stale lock from pid $ownerPid."
        }
    }
    Set-Content -LiteralPath $lockFile -Value $PID -Encoding utf8
    return $true
}

<#
    .SYNOPSIS
    Releases the worker lock held by this process.
#>
function Exit-ClaudeCronLock {
    [CmdletBinding()]
    param ()
    $lockFile = (Get-ClaudeCronPath).Lock
    if (-not (Test-Path -LiteralPath $lockFile)) { return }
    $owner = (Get-Content -LiteralPath $lockFile -Raw).Trim()
    if ($owner -eq "$PID") { Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue }
}
