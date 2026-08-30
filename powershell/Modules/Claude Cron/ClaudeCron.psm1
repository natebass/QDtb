<#
    The module manifest (.psd1) names this file as the root of the module.
    Private helpers load first so the public commands can rely on them.

    Paths are built with Join-Path rather than a literal separator: this module is
    developed on Linux Mint and a backslash there is a filename character, not a
    directory separator.
#>
foreach ($scope in @('Private', 'Public')) {
    $folder = Join-Path $PSScriptRoot 'Functions' $scope
    if (-not (Test-Path -LiteralPath $folder)) { continue }
    foreach ($functionFile in (Get-ChildItem -LiteralPath $folder -Filter '*.ps1' -File -Recurse | Sort-Object FullName)) {
        . $functionFile.FullName
    }
}
