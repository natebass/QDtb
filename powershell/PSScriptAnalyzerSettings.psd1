<#
    PSScriptAnalyzer settings for the PowerShell modules in this repository.

    Invoke-ScriptAnalyzer picks this up automatically when run from this folder, and
    Invoke-Tests.ps1 passes it explicitly.
#>
@{
    ExcludeRules = @(
        # These modules are interactive console utilities: coloured output is the feature,
        # and Write-Host is the only cmdlet that takes -ForegroundColor. The alternative
        # was tried here already and did not work - the calls had been switched to
        # Write-Information while keeping -ForegroundColor, which that cmdlet does not
        # accept, so every one of those functions threw on its first line of output.
        'PSAvoidUsingWriteHost'
    )
}

