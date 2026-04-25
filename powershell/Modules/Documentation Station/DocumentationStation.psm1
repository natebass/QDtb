
# Load Public Functions
Get-ChildItem -Path $PSScriptRoot\Source -Filter *.ps1 | ForEach-Object { . $_.FullName }
# Load Private Functions
Get-ChildItem -Path $PSScriptRoot\Source\Feature\PSReadLine -Filter *.ps1 | ForEach-Object { . $_.FullName }
# Export Public Functions
# Export-ModuleMember -Function (Get-ChildItem -Path "$PSScriptRoot\Source\*.ps1" | ForEach-Object {
#     (Get-Command -Name (Split-Path $_.Name -LeafBaseName)).Name
#     })
