foreach ($functionFile in (Get-ChildItem -Path "$PSScriptRoot\Functions\Public\*.ps1" -Recurse)) {
    . $functionFile
}
