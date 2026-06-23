
<#
    .SYNOPSIS
    Sets up the icon directory if it does not exist.
#>
function New-IconDirectory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [string]$IconDir = "icon"
    )
    if (-not (Test-Path -Path $IconDir)) {
        if ($PSCmdlet.ShouldProcess($IconDir, 'Create icon directory')) {
            New-Item -ItemType Directory -Path $IconDir -Force | Out-Null
        }
    }
    return $IconDir
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
    try {
        Set-Content -Path $indexPath -Value $indexContent
        Write-ModuleLog -Level "INFO" -Message "Created index file at $indexPath"
    }
    catch {
        Write-ModuleLog -Level "ERROR" -Message "Error creating index file: $_"
    }
}
