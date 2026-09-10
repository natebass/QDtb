<#
    Pester tests for ClaudeCron.

    Every test runs against a throwaway CLAUDE_CRON_HOME under the temp directory, so
    running these never touches the real queue. No test calls the Claude CLI; prompt
    behaviour is covered through the quota parser and command jobs stand in for runs.

    Invoke-Pester -Path ./Test
#>
BeforeAll {
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot
    $script:TestHome = Join-Path ([System.IO.Path]::GetTempPath()) "claude-cron-tests-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    $env:CLAUDE_CRON_HOME = $script:TestHome
    Import-Module (Join-Path $script:ModuleRoot 'ClaudeCron.psd1') -Force

    # These tests call Clear-ClaudeCronQueue -All. If CLAUDE_CRON_HOME were not picked up
    # for any reason - a stale module still loaded, an ordering change, a typo in the
    # variable name - that would empty the real queue instead of this throwaway one. Prove
    # the module resolved the temp root before a single destructive test is allowed to run.
    $resolvedRoot = (Get-ClaudeCronConfig).Root
    if ($resolvedRoot -ne $script:TestHome) {
        throw "Refusing to run: ClaudeCron resolved its root to '$resolvedRoot', not the test directory '$($script:TestHome)'."
    }
}

AfterAll {
    Remove-Module ClaudeCron -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $script:TestHome) {
        Remove-Item -LiteralPath $script:TestHome -Recurse -Force -ErrorAction SilentlyContinue
    }
    $env:CLAUDE_CRON_HOME = $null
}

Describe 'Cron expressions' {
    BeforeAll {
        # A Sunday, so the weekday cases have something to skip over.
        $script:Base = [datetime]'2026-08-30 12:34:00'
    }

    It 'resolves <Expression> to <Expected>' -ForEach @(
        @{ Expression = '@daily'; Expected = '2026-08-31 00:00' }
        @{ Expression = '@hourly'; Expected = '2026-08-30 13:00' }
        @{ Expression = '*/15 * * * *'; Expected = '2026-08-30 12:45' }
        @{ Expression = '0 8 * * 1-5'; Expected = '2026-08-31 08:00' }
        @{ Expression = '5,20 * * * *'; Expected = '2026-08-30 13:05' }
        @{ Expression = '30 3 1 * *'; Expected = '2026-09-01 03:30' }
        @{ Expression = '0 9 * * sun'; Expected = '2026-09-06 09:00' }
        @{ Expression = '0 0 * * 7'; Expected = '2026-09-06 00:00' }
        @{ Expression = '0 0 29 feb *'; Expected = '2028-02-29 00:00' }
    ) {
        $result = InModuleScope ClaudeCron -Parameters @{ e = $Expression; b = $script:Base } {
            param($e, $b) Get-ClaudeCronNextRun -Expression $e -After $b
        }
        $result.ToString('yyyy-MM-dd HH:mm') | Should -Be $Expected
    }

    It 'rejects an expression with the wrong field count' {
        { InModuleScope ClaudeCron { ConvertFrom-ClaudeCronExpression -Expression '0 8 * *' } } |
            Should -Throw -ExpectedMessage '*needs 5 fields*'
    }

    It 'rejects a field outside its range' {
        { InModuleScope ClaudeCron { ConvertFrom-ClaudeCronExpression -Expression '0 25 * * *' } } |
            Should -Throw -ExpectedMessage '*outside the allowed range*'
    }
}

Describe 'Interval parsing' {
    It 'reads <Interval> as <Expected>' -ForEach @(
        @{ Interval = '90m'; Expected = '01:30:00' }
        @{ Interval = '2h'; Expected = '02:00:00' }
        @{ Interval = '2h30m'; Expected = '02:30:00' }
        @{ Interval = '1d'; Expected = '1.00:00:00' }
        @{ Interval = '45s'; Expected = '00:00:45' }
        @{ Interval = '30'; Expected = '00:30:00' }
    ) {
        $result = InModuleScope ClaudeCron -Parameters @{ i = $Interval } {
            param($i) ConvertTo-ClaudeCronTimeSpan -Interval $i
        }
        $result.ToString() | Should -Be $Expected
    }

    It 'rejects text that is not a duration' {
        { InModuleScope ClaudeCron { ConvertTo-ClaudeCronTimeSpan -Interval 'soon' } } |
            Should -Throw -ExpectedMessage '*Could not read*'
    }
}

Describe 'Quota detection' {
    It 'trusts the machine readable sentinel and takes its reset time' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronQuotaFailure -Output 'Claude AI usage limit reached|1788000000' -ExitCode 1
        }
        $result.IsQuota | Should -BeTrue
        $result.ResetsAt | Should -Be ([System.DateTimeOffset]::FromUnixTimeSeconds(1788000000).LocalDateTime)
    }

    It 'reads a wall clock reset out of the message' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronQuotaFailure -Output 'Error: rate_limit_error - resets at 6pm' -ExitCode 1
        }
        $result.IsQuota | Should -BeTrue
        $result.ResetsAt.Hour | Should -Be 18
    }

    It 'falls back to the configured reset window when no time is given' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronQuotaFailure -Output 'quota exceeded' -ExitCode 1
        }
        $result.IsQuota | Should -BeTrue
        $result.ResetsAt | Should -BeGreaterThan (Get-Date).AddHours(4)
    }

    It 'does not trip on a successful run that merely mentions rate limits' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronQuotaFailure -Output 'Here is how to handle a 429 rate limit in your code.' -ExitCode 0
        }
        $result.IsQuota | Should -BeFalse
    }
}

Describe 'Auth detection' {
    It 'recognises an expired login' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronAuthFailure -Output 'Failed to authenticate: OAuth session expired and could not be refreshed' -ExitCode 1
        }
        $result.IsAuth | Should -BeTrue
    }

    It 'recognises an invalid API key' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronAuthFailure -Output 'Invalid API key - please run /login' -ExitCode 1
        }
        $result.IsAuth | Should -BeTrue
    }

    It 'ignores auth talk in a run that succeeded' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronAuthFailure -Output 'Your handler should return 401 unauthorized here.' -ExitCode 0
        }
        $result.IsAuth | Should -BeFalse
    }

    It 'is not confused with a quota failure' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronAuthFailure -Output 'Claude AI usage limit reached|1788000000' -ExitCode 1
        }
        $result.IsAuth | Should -BeFalse
    }
}

Describe 'Queue lifecycle' {
    AfterEach {
        Clear-ClaudeCronQueue -All -Confirm:$false
        Clear-ClaudeCronQuota -Confirm:$false | Out-Null
    }

    It 'queues a command and reports it as due' {
        $job = Add-ClaudeCronCommand -Command 'Write-Output ok' -Name 'unit-due'
        $job.Status | Should -Be 'Pending'
        (Get-ClaudeCronJob -Due).Name | Should -Contain 'unit-due'
    }

    It 'holds a job until its -At time' {
        Add-ClaudeCronCommand -Command 'Write-Output later' -Name 'unit-later' -At (Get-Date).AddHours(2) | Out-Null
        (Get-ClaudeCronJob -Due).Name | Should -Not -Contain 'unit-later'
    }

    It 'runs a due job and records the outcome' {
        Add-ClaudeCronCommand -Command 'Write-Output "hello from claude cron"' -Name 'unit-run' | Out-Null
        Invoke-ClaudeCronQueue | Out-Null

        $job = Get-ClaudeCronJob 'unit-run'
        $job.Status | Should -Be 'Done'
        $job.LastExitCode | Should -Be 0
        $job.RunCount | Should -Be 1
        (Get-ClaudeCronLog 'unit-run') -join "`n" | Should -Match 'hello from claude cron'
    }

    It 'retries a failing job and gives up at MaxAttempts' {
        Set-ClaudeCronConfig -MaxAttempts 2 -Confirm:$false | Out-Null
        Add-ClaudeCronCommand -Command 'exit 3' -Name 'unit-bad' | Out-Null

        Invoke-ClaudeCronQueue | Out-Null
        (Get-ClaudeCronJob 'unit-bad').Status | Should -Be 'Pending'
        (Get-ClaudeCronJob 'unit-bad').Attempts | Should -Be 1

        Invoke-ClaudeCronQueue -Identity 'unit-bad' -Force | Out-Null
        (Get-ClaudeCronJob 'unit-bad').Status | Should -Be 'Failed'
    }

    It 'reschedules a repeating job instead of retiring it' {
        Add-ClaudeCronCommand -Command 'Write-Output tick' -Name 'unit-repeat' -Every '1h' | Out-Null
        Invoke-ClaudeCronQueue -Identity 'unit-repeat' -Force | Out-Null

        $job = Get-ClaudeCronJob 'unit-repeat'
        $job.Status | Should -Be 'Pending'
        $job.RunCount | Should -Be 1
        $next = InModuleScope ClaudeCron -Parameters @{ t = $job.RunAfter } {
            param($t) ConvertFrom-ClaudeCronTimestamp $t
        }
        $next | Should -BeGreaterThan (Get-Date).AddMinutes(50)
    }

    It 'retires a repeating job once MaxRuns is reached' {
        Add-ClaudeCronCommand -Command 'Write-Output once' -Name 'unit-maxruns' -Every '1h' -MaxRuns 1 | Out-Null
        Invoke-ClaudeCronQueue -Identity 'unit-maxruns' -Force | Out-Null
        (Get-ClaudeCronJob 'unit-maxruns').Status | Should -Be 'Done'
    }

    It 'skips a disabled job' {
        Add-ClaudeCronCommand -Command 'Write-Output nope' -Name 'unit-disabled' | Out-Null
        Set-ClaudeCronJob 'unit-disabled' -Disable -Confirm:$false | Out-Null
        Invoke-ClaudeCronQueue | Out-Null
        (Get-ClaudeCronJob 'unit-disabled').Status | Should -Be 'Disabled'
    }

    It 'removes a job and its log' {
        $job = Add-ClaudeCronCommand -Command 'Write-Output bye' -Name 'unit-remove'
        Remove-ClaudeCronJob 'unit-remove' -Confirm:$false
        Get-ClaudeCronJob 'unit-remove' | Should -BeNullOrEmpty
        Test-Path -LiteralPath $job.LogFile | Should -BeFalse
    }

    It 'refuses an ambiguous identity' {
        Add-ClaudeCronCommand -Command 'Write-Output a' -Name 'dup' | Out-Null
        Add-ClaudeCronCommand -Command 'Write-Output b' -Name 'dup' | Out-Null
        { Remove-ClaudeCronJob 'dup' -Confirm:$false } | Should -Throw -ExpectedMessage '*matches 2 jobs*'
    }
}

Describe 'Quota pause' {
    AfterEach {
        Clear-ClaudeCronQueue -All -Confirm:$false
        Clear-ClaudeCronQuota -Confirm:$false | Out-Null
    }

    It 'reports the block and leaves due work untouched' {
        Set-ClaudeCronQuota -In '2h' -Reason 'unit test' -Confirm:$false | Out-Null
        (Get-ClaudeCronQuota).Blocked | Should -BeTrue

        Add-ClaudeCronCommand -Command 'Write-Output held' -Name 'unit-held' | Out-Null
        Invoke-ClaudeCronQueue | Out-Null
        (Get-ClaudeCronJob 'unit-held').Status | Should -Be 'Pending'
    }

    It 'drains as soon as the block is lifted' {
        Set-ClaudeCronQuota -In '2h' -Confirm:$false | Out-Null
        Add-ClaudeCronCommand -Command 'Write-Output released' -Name 'unit-released' | Out-Null
        Invoke-ClaudeCronQueue | Out-Null

        Clear-ClaudeCronQuota -Confirm:$false | Out-Null
        (Get-ClaudeCronQuota).Blocked | Should -BeFalse
        Invoke-ClaudeCronQueue | Out-Null
        (Get-ClaudeCronJob 'unit-released').Status | Should -Be 'Done'
    }

    It 'expires a block whose reset time has passed' {
        Set-ClaudeCronQuota -Until (Get-Date).AddMinutes(-1) -Confirm:$false | Out-Null
        (Get-ClaudeCronQuota).Blocked | Should -BeFalse
    }
}

Describe 'Configuration' {
    It 'round-trips a setting through config.json' {
        Set-ClaudeCronConfig -PollSeconds 123 -Confirm:$false | Out-Null
        (Get-ClaudeCronConfig).PollSeconds | Should -Be 123
    }

    It 'rejects a working directory that does not exist' {
        { Set-ClaudeCronConfig -DefaultWorkingDirectory '/definitely/not/here' -Confirm:$false } |
            Should -Throw -ExpectedMessage '*does not exist*'
    }
}

Describe 'Scheduler installation' {
    It 'builds a drain command that imports this module' {
        $drain = Get-ClaudeCronDrainCommand
        $drain.ModulePath | Should -Match 'ClaudeCron\.psd1$'
        $drain.CommandLine | Should -Match 'Invoke-ClaudeCronQueue'
    }

    It 'leaves the crontab alone under -WhatIf' -Skip:($IsWindows -or -not (Get-Command crontab -ErrorAction SilentlyContinue)) {
        $before = (Get-ClaudeCronSchedule).CronLine
        Install-ClaudeCronSchedule -Cron '*/10 * * * *' -WhatIf -InformationAction SilentlyContinue
        (Get-ClaudeCronSchedule).CronLine | Should -Be $before
    }

    It 'validates the cron expression before touching the crontab' -Skip:($IsWindows) {
        { Install-ClaudeCronSchedule -Cron 'every ten minutes' -WhatIf } | Should -Throw
    }
}

Describe 'Failure detection is scoped to the error, not the transcript' {
    It 'ignores quota words in the body of a long answer' {
        $result = InModuleScope ClaudeCron {
            $body = @('Here is how to handle rate limiting.') + (1..40 | ForEach-Object { "line $_" })
            $run = [pscustomobject]@{
                StdOut = ($body -join "`n")
                StdErr = ''
            }
            Test-ClaudeCronQuotaFailure -Output (Get-ClaudeCronFailureText -Run $run) -ExitCode 1
        }
        $result.IsQuota | Should -BeFalse
    }

    It 'still catches the limit when the CLI reports it on stderr' {
        $result = InModuleScope ClaudeCron {
            $run = [pscustomobject]@{
                StdOut = 'Working on it.'
                StdErr = 'API Error: 429 usage limit reached'
            }
            Test-ClaudeCronQuotaFailure -Output (Get-ClaudeCronFailureText -Run $run) -ExitCode 1
        }
        $result.IsQuota | Should -BeTrue
    }

    It 'does not read a bare number in prose as an HTTP status' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronQuotaFailure -Output 'The array had 429 entries left over.' -ExitCode 1
        }
        $result.IsQuota | Should -BeFalse
    }

    It 'does not read the word unauthorized in prose as a sign-out' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronAuthFailure -Output 'The endpoint should reject unauthorized callers.' -ExitCode 1
        }
        $result.IsAuth | Should -BeFalse
    }

    It 'still catches a real 401 from the CLI' {
        $result = InModuleScope ClaudeCron {
            Test-ClaudeCronAuthFailure -Output 'API Error: 401 Unauthorized' -ExitCode 1
        }
        $result.IsAuth | Should -BeTrue
    }
}

Describe 'Worker lock' {
    AfterEach {
        $lock = InModuleScope ClaudeCron { (Get-ClaudeCronPath).Lock }
        Remove-Item -LiteralPath $lock -Force -ErrorAction SilentlyContinue
    }

    It 'refuses to start while another live process holds the lock' {
        $taken = InModuleScope ClaudeCron {
            $lock = (Get-ClaudeCronPath).Lock
            # pid 1 is always running and is never this process.
            Set-Content -LiteralPath $lock -Value '{"Pid":1}' -Encoding utf8
            Enter-ClaudeCronLock
        }
        $taken | Should -BeFalse
    }

    It 'takes over a lock whose process is gone' {
        $taken = InModuleScope ClaudeCron {
            $lock = (Get-ClaudeCronPath).Lock
            # A pid above the maximum can never be running.
            Set-Content -LiteralPath $lock -Value '{"Pid":4194304}' -Encoding utf8
            Enter-ClaudeCronLock
        }
        $taken | Should -BeTrue
    }

    It 'does not release a lock owned by someone else' {
        $survived = InModuleScope ClaudeCron {
            $lock = (Get-ClaudeCronPath).Lock
            Set-Content -LiteralPath $lock -Value '{"Pid":1}' -Encoding utf8
            Exit-ClaudeCronLock
            Test-Path -LiteralPath $lock
        }
        $survived | Should -BeTrue
    }

    It 'reports no worker when the lock is stale' {
        $reported = InModuleScope ClaudeCron {
            Set-Content -LiteralPath (Get-ClaudeCronPath).Lock -Value '{"Pid":4194304}' -Encoding utf8
            Get-ClaudeCronWorkerPid
        }
        $reported | Should -BeNullOrEmpty
    }
}

Describe 'Recovery from a stopped worker' {
    AfterEach { Clear-ClaudeCronQueue -All -Confirm:$false }

    It 'returns a job left Running to the queue' {
        Add-ClaudeCronCommand -Command 'Write-Output stuck' -Name 'unit-stuck' | Out-Null
        $job = Get-ClaudeCronJob 'unit-stuck'
        $job.Status = 'Running'
        InModuleScope ClaudeCron -Parameters @{ j = $job } { param($j) Write-ClaudeCronJob -Job $j | Out-Null }

        InModuleScope ClaudeCron { Reset-ClaudeCronStaleJob }

        $recovered = Get-ClaudeCronJob 'unit-stuck'
        $recovered.Status | Should -Be 'Pending'
        $recovered.Attempts | Should -Be 1
    }

    It 'gives up on a job that keeps taking the worker down' {
        Add-ClaudeCronCommand -Command 'Write-Output stuck' -Name 'unit-stuck-out' | Out-Null
        $job = Get-ClaudeCronJob 'unit-stuck-out'
        $job.Status = 'Running'
        $job.Attempts = 2
        $job.MaxAttempts = 3
        InModuleScope ClaudeCron -Parameters @{ j = $job } { param($j) Write-ClaudeCronJob -Job $j | Out-Null }

        InModuleScope ClaudeCron { Reset-ClaudeCronStaleJob }
        (Get-ClaudeCronJob 'unit-stuck-out').Status | Should -Be 'Failed'
    }
}

Describe 'Notifications' {
    AfterEach {
        Set-ClaudeCronConfig -NotifyCommand '' -Confirm:$false | Out-Null
        Clear-ClaudeCronQueue -All -Confirm:$false
    }

    It 'passes a job name containing shell syntax through as text' {
        $marker = Join-Path ([System.IO.Path]::GetTempPath()) "claude-cron-injection-$([guid]::NewGuid().ToString('N').Substring(0,8))"
        $captured = "$marker.out"
        Set-ClaudeCronConfig -NotifyCommand "printf '%s' '{message}' > '$captured'" -Confirm:$false | Out-Null

        InModuleScope ClaudeCron -Parameters @{ m = "boom `$(touch '$marker') done" } {
            param($m) Send-ClaudeCronNotification -Title 'unit' -Message $m
        }

        Test-Path -LiteralPath $marker | Should -BeFalse -Because 'the command substitution must never be evaluated'
        (Get-Content -LiteralPath $captured -Raw) | Should -Match '\$\(touch'
        Remove-Item -LiteralPath $captured -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Housekeeping' {
    It 'removes the log files of the jobs it clears' {
        $job = Add-ClaudeCronCommand -Command 'Write-Output tidy' -Name 'unit-tidy'
        Invoke-ClaudeCronQueue -Identity 'unit-tidy' -Force | Out-Null
        Test-Path -LiteralPath $job.LogFile | Should -BeTrue

        Clear-ClaudeCronQueue -All -Confirm:$false
        Test-Path -LiteralPath $job.LogFile | Should -BeFalse
    }

    It 'records every run of a repeating job in the history' {
        $historyPath = InModuleScope ClaudeCron { (Get-ClaudeCronPath).History }
        Remove-Item -LiteralPath $historyPath -Force -ErrorAction SilentlyContinue

        Add-ClaudeCronCommand -Command 'Write-Output again' -Name 'unit-history' -Every '1h' | Out-Null
        Invoke-ClaudeCronQueue -Identity 'unit-history' -Force | Out-Null
        Invoke-ClaudeCronQueue -Identity 'unit-history' -Force | Out-Null

        @(Get-Content -LiteralPath $historyPath).Count | Should -Be 2
        Clear-ClaudeCronQueue -All -Confirm:$false
    }

    It 'leaves no temp file behind when a job file is written' {
        Add-ClaudeCronCommand -Command 'Write-Output atomic' -Name 'unit-atomic' | Out-Null
        $queue = InModuleScope ClaudeCron { (Get-ClaudeCronPath).Queue }
        @(Get-ChildItem -LiteralPath $queue -Filter '*.tmp').Count | Should -Be 0
        Clear-ClaudeCronQueue -All -Confirm:$false
    }
}

Describe 'Crontab handling' -Skip:($IsWindows -or -not (Get-Command crontab -ErrorAction SilentlyContinue)) {
    It 'reads an absent crontab as no entries rather than failing' {
        # Read-only: this never writes a crontab.
        { InModuleScope ClaudeCron { Read-ClaudeCronCrontab } } | Should -Not -Throw
    }

    It 'escapes the percent sign cron would read as end-of-command' {
        $escaped = InModuleScope ClaudeCron {
            ConvertTo-ClaudeCronCommandField -Command 'date +%Y >> /tmp/x'
        }
        $escaped | Should -Be 'date +\%Y >> /tmp/x'
    }

    It 'refuses a PATH containing a line break' {
        { Install-ClaudeCronSchedule -Path "/usr/bin`n* * * * * evil" -WhatIf } |
            Should -Throw -ExpectedMessage '*line break*'
    }

    It 'pins the store root into the drain command' {
        (Get-ClaudeCronDrainCommand).Root | Should -Be $script:TestHome
    }
}
