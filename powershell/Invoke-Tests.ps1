<#
    .SYNOPSIS
    Runs every PowerShell module test suite in this repository, checks that it left
    nothing behind, and lints the whole tree.

    .DESCRIPTION
    Pester is pointed at each module's test folder rather than at the tree, because the
    suites import their modules by path and a stray discovery pass over the module source
    is what used to make Import-Module run test files.

    The run is bracketed by a fingerprint of the things a test must never touch: the
    user's crontab, the systemd user units, and the real ClaudeCron store. If any of them
    differs afterwards, the run is reported as non-hermetic and fails, whatever Pester
    thought of the assertions. A suite that quietly reaches outside its sandbox is a
    problem worth failing over even when its tests pass.

    .PARAMETER Path
    Limit the run to one module folder, e.g. -Path 'Claude Cron'.

    .PARAMETER SkipAnalyzer
    Skip the PSScriptAnalyzer pass.

    .EXAMPLE
    ./Invoke-Tests.ps1

    .EXAMPLE
    ./Invoke-Tests.ps1 -Path 'Claude Cron'
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [switch]$SkipAnalyzer
)

# Deliberately not $ErrorActionPreference = 'Stop': Pester and its mocks emit
# non-terminating errors as part of normal operation, and promoting those to exceptions
# makes unrelated tests fail inside the runner while passing under a plain Invoke-Pester.
# Failures are decided by the Pester result object at the end instead.
$root = $PSScriptRoot

function Get-HermeticFingerprint {
    <#
        .SYNOPSIS
        Snapshots the machine state no test is allowed to change.
    #>
    [CmdletBinding()]
    param ()
    $crontab = if (Get-Command crontab -CommandType Application -ErrorAction SilentlyContinue) {
        (& crontab -l 2>&1 | Out-String)
    }
    else {
        '(no crontab command)'
    }
    $units = Get-ChildItem -LiteralPath (Join-Path $HOME '.config/systemd/user') -Filter '*claude-cron*' -ErrorAction SilentlyContinue |
        ForEach-Object { "$($_.Name):$($_.Length)" }
    $store = Get-ChildItem -LiteralPath (Join-Path $HOME '.config/claude-cron') -Recurse -File -ErrorAction SilentlyContinue |
        ForEach-Object { "$($_.FullName):$($_.Length)" }
    return [pscustomobject]@{
        Crontab = $crontab
        Units   = ($units | Sort-Object) -join '|'
        Store   = ($store | Sort-Object) -join '|'
    }
}

$suites = Get-ChildItem -LiteralPath (Join-Path $root 'Modules') -Directory |
    Where-Object { -not $Path -or $_.Name -eq $Path } |
    ForEach-Object {
        # Test/ in most modules, Resources/ in QDtb.SvgToReact.
        foreach ($folder in @('Test', 'Tests', 'Resources')) {
            $candidate = Join-Path $_.FullName $folder
            if ((Test-Path -LiteralPath $candidate) -and
                @(Get-ChildItem -LiteralPath $candidate -Filter '*.Tests.ps1' -File).Count -gt 0) {
                $candidate
            }
        }
    }

if (-not $suites) { throw "No test suites found$(if ($Path) { " for '$Path'" })." }

$before = Get-HermeticFingerprint
$results = Invoke-Pester -Path $suites -Output Detailed -PassThru
$after = Get-HermeticFingerprint

$leaks = foreach ($field in 'Crontab', 'Units', 'Store') {
    if ($before.$field -ne $after.$field) { $field }
}

# A sandbox left behind means a suite failed before its AfterAll, or did not use one.
$strays = @(Get-ChildItem -LiteralPath ([System.IO.Path]::GetTempPath()) -Directory -Filter 'pester-*' -ErrorAction SilentlyContinue)

''
'=' * 72
"Suites   : $($suites.Count)"
"Tests    : $($results.PassedCount) passed, $($results.FailedCount) failed, $($results.SkippedCount) skipped"
"Hermetic : $(if ($leaks) { "NO - changed: $($leaks -join ', ')" } else { 'yes - crontab, systemd units and the real store are untouched' })"
if ($strays) { "Strays   : $($strays.Count) sandbox(es) left in the temp directory: $($strays.Name -join ', ')" }

if (-not $SkipAnalyzer) {
    # The whole tree, not just Modules: Scripts/ had 28 calls passing -ForegroundColor to
    # Write-Information, which that cmdlet does not accept, and nothing was looking at it.
    $findings = Invoke-ScriptAnalyzer -Path $root -Recurse -Severity Warning, Error `
        -Settings (Join-Path $root 'PSScriptAnalyzerSettings.psd1')
    "Analyzer : $($findings.Count) finding(s)"
    $findings | Format-Table -AutoSize RuleName, ScriptName, Line, Message | Out-String | Write-Information -InformationAction Continue
}
'=' * 72

if ($leaks) { throw "Tests are not hermetic: they changed $($leaks -join ', ')." }
if ($results.FailedCount -gt 0) { throw "$($results.FailedCount) test(s) failed." }

