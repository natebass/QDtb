
<#
React component file using template.
.PARAMETER FileName 
    The name of the component file to be created. Default is "f".
#>
function Save-Sample {
    param (
        [string]$FileName = "f"
    )
    $templatePath = "$PSScriptRoot/../../../../../templates/other/js/f.tsx"
    $destinationPath = "./src/components/$FileName.tsx"
    $destinationDir = Split-Path -Path $destinationPath
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force
    }
    if (Test-Path $templatePath) {
        $content = Get-Content -Path $templatePath
        $content = $content -replace "function f", "function $FileName"
        $content = $content -replace "export default function f", "export default function $FileName"
        $content = $content -replace "export interface fProps", "export interface ${FileName}Props"
        $content | Set-Content -Path $destinationPath -Force
        Write-Output "File created at $destinationPath using template from $templatePath"
    }
    else {
        Write-Output "Template file not found at $templatePath"
    }
}
