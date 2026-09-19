<#
    Pester tests for QDtb.Utility.

    Hermetic, and this suite is the reason the sandbox exists. It used to call
    Start-MyProject for real, which fetches a hardcoded repository, starts `npm run dev`
    and `uv run fastapi dev` as background jobs, and then blocks on
    Read-Host "Press Enter to exit" - so running the tests hung the whole run until
    someone noticed and pressed a key. It also downloaded a file from the network into
    C:\Users\nateb\Desktop and waited on a real keypress in the shell test.

    Every one of those boundaries is mocked here: git, Start-Job, Receive-Job, Read-Host
    and the location stack. What is left is the control flow, which is the part worth
    testing anyway.

    Invoke-Pester -Path ./Test
#>
BeforeAll {
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path (Split-Path -Parent (Split-Path -Parent $script:ModuleRoot)) 'Tests/TestSandbox.psm1') -Force
    Import-Module (Join-Path $script:ModuleRoot 'QDtb.Utility.psd1') -Force
    $script:Sandbox = New-PesterSandbox -Name 'QDtb-utility'
}

AfterAll {
    Remove-Module QDtb.Utility -Force -ErrorAction SilentlyContinue
    Remove-PesterSandbox -Sandbox $script:Sandbox
    Remove-Module TestSandbox -Force -ErrorAction SilentlyContinue
}

Describe 'Module surface' {
    It 'exports every function the manifest promises' {
        $declared = (Import-PowerShellDataFile (Join-Path $script:ModuleRoot 'QDtb.Utility.psd1')).FunctionsToExport
        $actual = (Get-Command -Module QDtb.Utility).Name
        $declared | Where-Object { $_ -notin $actual } | Should -BeNullOrEmpty
    }

    It 'loads something at all' {
        # The loader globbed Functions/Public while the folder was Source/Public, so the
        # module imported cleanly and exported nothing whatsoever.
        @(Get-Command -Module QDtb.Utility).Count | Should -BeGreaterThan 0
    }
}

Describe 'Write-RainbowPrompt' {
    It 'writes three chevrons on Unix' {
        $written = (Write-RainbowPrompt -platform 'Unix' 6>&1 | ForEach-Object { $_.MessageData.Message }) -join ''
        $written | Should -Match '❯'
        ([regex]::Matches($written, '❯')).Count | Should -Be 3
    }

    It 'writes three chevrons on anything else' {
        $written = (Write-RainbowPrompt -platform 'Win32NT' 6>&1 | ForEach-Object { $_.MessageData.Message }) -join ''
        ([regex]::Matches($written, '>')).Count | Should -Be 3
    }

    It 'never waits for a keypress' {
        # The old test called $host.UI.RawUI.ReadKey after this and blocked the run.
        # Write-RainbowPrompt itself must return on its own.
        { Write-RainbowPrompt -platform 'Unix' 6>&1 | Out-Null } | Should -Not -Throw
    }
}

Describe 'Start-MyProject' {
    BeforeEach {
        # Every boundary this function touches, stubbed. Without these the test starts
        # two dev servers and then waits for a human.
        Mock -ModuleName QDtb.Utility Push-Location { }
        Mock -ModuleName QDtb.Utility Pop-Location { }
        # Returns nothing on purpose. A stub object here would be piped into Receive-Job,
        # fail to bind to its [Job[]] parameter and print a binding error per call; with an
        # empty pipeline Receive-Job simply never runs.
        Mock -ModuleName QDtb.Utility Start-Job { }
        Mock -ModuleName QDtb.Utility Receive-Job { }
        Mock -ModuleName QDtb.Utility Read-Host { '' }
        Mock -ModuleName QDtb.Utility git { }
    }

    It 'pulls when the working tree is clean' {
        Mock -ModuleName QDtb.Utility git { } -ParameterFilter { $args -contains 'status' }
        Start-MyProject -WhatIf:$false -Confirm:$false | Out-Null
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'pull' } -Times 1 -Exactly
    }

    It 'does not pull when the working tree is dirty' {
        Mock -ModuleName QDtb.Utility git { ' M somefile.txt' } -ParameterFilter { $args -contains 'status' }
        Start-MyProject -WhatIf:$false -Confirm:$false | Out-Null
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'pull' } -Times 0 -Exactly
    }

    It 'always fetches first' {
        Start-MyProject -WhatIf:$false -Confirm:$false | Out-Null
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'fetch' } -Times 1 -Exactly
    }

    It 'starts a job for the frontend and one for the backend' {
        Start-MyProject -WhatIf:$false -Confirm:$false | Out-Null
        Should -Invoke -ModuleName QDtb.Utility Start-Job -Times 2 -Exactly
    }

    It 'takes the foreground path by default' {
        # The two paths are told apart by what the function emits: 'b' foreground, 'a'
        # background. Counting Receive-Job calls does not work, because a stubbed job
        # object cannot bind to its -Job parameter.
        Start-MyProject -WhatIf:$false -Confirm:$false | Should -Contain 'b'
    }

    It 'takes the background path with -RunInBackground' {
        $output = Start-MyProject -RunInBackground -WhatIf:$false -Confirm:$false
        $output | Should -Contain 'a'
        $output | Should -Not -Contain 'b'
        Should -Invoke -ModuleName QDtb.Utility Start-Job -Times 2 -Exactly
    }

    It 'blocks on a keypress before returning' {
        # Documented rather than endorsed: this is what made the suite hang. A function
        # meant to be callable from a script should not end in Read-Host.
        Start-MyProject -WhatIf:$false -Confirm:$false | Out-Null
        Should -Invoke -ModuleName QDtb.Utility Read-Host -Times 1 -Exactly
    }

    It 'starts no jobs under -WhatIf' {
        Start-MyProject -WhatIf | Out-Null
        Should -Invoke -ModuleName QDtb.Utility Start-Job -Times 0 -Exactly
    }
}

Describe 'Sync-Fork' {
    BeforeEach {
        Mock -ModuleName QDtb.Utility git { }
    }

    It 'refuses to sync a dirty working tree' {
        Mock -ModuleName QDtb.Utility git { ' M conflicted.txt' } -ParameterFilter { $args -contains 'status' }
        Sync-Fork -ForkPath $script:Sandbox.Path -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable syncError | Out-Null
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'merge' } -Times 0 -Exactly
    }

    It 'merges and pushes a clean fork' {
        Mock -ModuleName QDtb.Utility git { 'main' } -ParameterFilter { $args -contains 'rev-parse' }
        Sync-Fork -ForkPath $script:Sandbox.Path -Confirm:$false | Out-Null
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'merge' } -Times 1 -Exactly
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'push' } -Times 1 -Exactly
    }

    It 'merges and pushes nothing under -WhatIf' {
        Mock -ModuleName QDtb.Utility git { 'main' } -ParameterFilter { $args -contains 'rev-parse' }
        Sync-Fork -ForkPath $script:Sandbox.Path -WhatIf | Out-Null
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'merge' } -Times 0 -Exactly
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'push' } -Times 0 -Exactly
    }

    It 'still fetches upstream under -WhatIf' {
        Sync-Fork -ForkPath $script:Sandbox.Path -WhatIf | Out-Null
        Should -Invoke -ModuleName QDtb.Utility git -ParameterFilter { $args -contains 'fetch' } -Times 1 -Exactly
    }
}

