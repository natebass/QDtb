<#
    The module manifest (.psd1) names this file as the root of the module.

    Note the -Exclude on the source glob: the test suite used to live in Source/, so
    importing the module dot-sourced it and ran the Describe blocks as a side effect of
    Import-Module. The suite now lives in Test/, and the exclusion keeps it that way if
    one is ever added back here.
#>
foreach ($folder in @('Source', 'Source/Feature/PSReadLine')) {
    $path = Join-Path $PSScriptRoot $folder
    if (-not (Test-Path -LiteralPath $path)) { continue }
    foreach ($functionFile in (Get-ChildItem -LiteralPath $path -Filter '*.ps1' -File -Exclude '*.Tests.ps1' | Sort-Object Name)) {
        . $functionFile.FullName
    }
}

