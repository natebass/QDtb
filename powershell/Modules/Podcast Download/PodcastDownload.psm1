
Get-ChildItem -Path $PSScriptRoot\Source -Filter *.ps1 | ForEach-Object { . $_.FullName }
