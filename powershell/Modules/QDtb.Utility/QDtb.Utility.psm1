<#
    The module manifest (.psd1) names this file as the root of the module.

    The glob says Source, not Functions: the folder was renamed and this file was not,
    so the module loaded nothing at all and every name in FunctionsToExport was missing.
    Private helpers load first so the public functions can rely on them.
#>
foreach ($scope in @('Private', 'Public')) {
    $folder = Join-Path $PSScriptRoot 'Source' $scope
    if (-not (Test-Path -LiteralPath $folder)) { continue }
    foreach ($functionFile in (Get-ChildItem -LiteralPath $folder -Filter '*.ps1' -File -Recurse -Exclude '*.Tests.ps1' | Sort-Object FullName)) {
        . $functionFile.FullName
    }
}

