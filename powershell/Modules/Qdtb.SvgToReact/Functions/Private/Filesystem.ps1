
<#
    .SYNOPSIS
    Sets up the icon directory if it does not exist.
#>
function New-IconDirectory {
    [CmdletBinding()]
    param (
        [string]$IconDir = "icon"
    )
    if (-not (Test-Path -Path $IconDir)) { New-Item -ItemType Directory -Path $iconDir | Out-Null }
    return $iconDir
}
<#
    .SYNOPSIS
    Converts a filename to PascalCase.
#>
function Convert-ToPascalCase {
    param ([string]$filename)
    $cleanName = [regex]::Replace([System.IO.Path]::GetFileNameWithoutExtension($filename), '[^a-zA-Z0-9]', ' ')
    return ($cleanName -split ' ' | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() }) -join ''
}
<#
    .SYNOPSIS
    Creates an index file exporting all components.
#>
function CreateIndexFile {
    param ([string]$iconDir, [System.Collections.Generic.HashSet[string]]$componentNames)
    $indexContent = $componentNames | Sort-Object | ForEach-Object { "export * from './$_';" } -join "`n"
    $indexPath = Join-Path -Path $iconDir -ChildPath "index.ts"
    try { Set-Content -Path $indexPath -Value $indexContent; Write-Log -level "INFO" -message "Created index file at $indexPath" }
    catch { Write-Log -level "ERROR" -message "Error creating index file: $_" }
}
