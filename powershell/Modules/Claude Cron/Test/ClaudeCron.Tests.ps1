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
