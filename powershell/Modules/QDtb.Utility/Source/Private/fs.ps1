function Remove-File {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [int]$Time = 5
    )

    <#
.SYNOPSIS
    Removes files matching a specified pattern from a given path with a user-defined countdown.

.SYNOPSIS
    Removes files matching the pattern parameter from the path parameter. It offers a customizable countdown
    before deletion to allow for user interaction or confirmation.

    ## Parameters (3)

    path
    [string] (Mandatory) The path to the directory containing the files to be removed.

    pattern
    [string] (Mandatory) The pattern to match against file names. Wildcards are supported.

    time
    [int] (Optional) The number of seconds to wait before removing the files. Defaults to 5.

.EXAMPLE
    Removes all .txt files from the C:\Temp directory after a 10-second countdown:
    ```PowerShell
    Remove-Files -Path "C:\Temp" -Pattern "*.txt" -Time 10
    ```

.NOTES
    This function uses a countdown to provide a visual confirmation before deleting files.
    Be cautious when removing files, as the action cannot be undone easily.
    Consider using the -WhatIf parameter with Remove-Item to preview the files that would be deleted.
#>
    Write-Information "Removing files from '$Path' matching pattern '$Pattern' in $Time seconds."
    # Countdown
    $Time..0 | ForEach-Object { if ($_ -gt 0) { Write-Information $_ }; Start-Sleep -Seconds 1 }
    # Remove matching files
    Get-ChildItem $Path | Where-Object { $_.Name -match $Pattern } | Remove-Item
}
function Edit-ContentAndFileName {

    <#
.SYNOPSIS
WARNING: Don't use this, it is currently broken by overwriting files with the wrong name.
Replaces a string in all files in a directory and renames the files.

.SYNOPSIS
This script takes a directory path, old string, new string, and a rename pattern as input.
It iterates through all files in the specified directory and its subdirectories,
replaces the old string with the new string in each file, and renames the file
according to the provided pattern.

.PARAMETER DirectoryPath
The path to the directory containing the files.

.PARAMETER OldString
The string to be replaced.

.PARAMETER NewString
The replacement string.

.PARAMETER RenamePattern
The pattern for renaming files. `{0}` will be replaced with the original filename without the extension.

.EXAMPLE
Replace "old_text" with "new_text" in all .txt files in the current directory and rename them to "new_file_{0}.txt":

```powershell
Edit-ContentAndFileName -DirectoryPath . -OldString "old_text" -NewString "new_text" -RenamePattern "new_file_{0}.txt"
```
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$DirectoryPath = ".",

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$OldString = "NwbUtility",

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$NewString = "DiosTeB",

        [Parameter(Mandatory = $false)]
        [string]$RenamePattern = "{0}_modified.txt"
    )
    $files = Get-ChildItem $DirectoryPath -Recurse -File
    foreach ($file in $files) {
        (Get-Content $file.FullName) -replace $OldString, $NewString | Set-Content $file.FullName
        $newFileName = $RenamePattern -f $file.BaseName
        Rename-Item $file.FullName -NewName $newFileName
    }
}
function Get-StorageAnalysis {
    <#
.SYNOPSIS
Analyzes the storage usage of a specified directory.

.SYNOPSIS
This cmdlet calculates the total size of a directory and its subdirectories,
displays the total size in gigabytes, and lists the top 10 largest files in the directory.

.PARAMETER DirectoryPath
Specifies the path to the directory to analyze. Defaults to the current directory.

.EXAMPLE
Get-StorageAnalysis -DirectoryPath "C:\Users\YourUserName\Documents"
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$DirectoryPath = "."
    )

    $items = Get-ChildItem $DirectoryPath -Recurse
    $totalSizeGB = [math]::Round(($items | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
    Write-Information "Total size of the directory: $totalSizeGB GB"
    $items | Where-Object { $_.PSIsContainer -eq $false } | Sort-Object -Property Length -Descending | Select-Object -First 10 | Format-Table -AutoSize
    # Other
    # Get-ChildItem -Path "C:\Your\Directory\Path" -Recurse | Measure-Object -Property Length -Sum | Format-Table -AutoSize
}

function Compare-Directory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$DestinationPath
    )
    # Resolve paths to handle relative syntax like '.' or '~'
    $dir1 = (Resolve-Path $SourcePath).Path
    $dir2 = (Resolve-Path $DestinationPath).Path
    Write-Verbose "Source Root: $dir1"
    Write-Verbose "Destination Root: $dir2"
    Write-Information "Scanning folders recursively...`n" -ForegroundColor Cyan
    # 1. Get all relative file paths from both directories
    $files1 = Get-ChildItem -Path $dir1 -File -Recurse | ForEach-Object { $_.FullName.Substring($dir1.Length + 1) }
    $files2 = Get-ChildItem -Path $dir2 -File -Recurse | ForEach-Object { $_.FullName.Substring($dir2.Length + 1) }
    # 2. Find structural differences (Missing files)
    $structuralDiff = Compare-Object $files1 $files2
    $missingIn2 = $structuralDiff | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    $missingIn1 = $structuralDiff | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
    if ($missingIn2) {
        Write-Information "--- FILES ONLY IN SOURCE ---" -ForegroundColor Red
        $missingIn2 | ForEach-Object { Write-Information "Missing in Destination: $_" }
        Write-Information ""
    }
    if ($missingIn1) {
        Write-Information "--- FILES ONLY IN DESTINATION ---" -ForegroundColor Red
        $missingIn1 | ForEach-Object { Write-Information "Missing in Source: $_" }
        Write-Information ""
    }
    # 3. Compare contents of files present in both directories
    Write-Verbose "Checking hashes for overlapping files..."
    $commonFiles = $files1 | Where-Object { $_ -in $files2 }
    $differencesFound = 0
    foreach ($relPath in $commonFiles) {
        $path1 = Join-Path $dir1 $relPath
        $path2 = Join-Path $dir2 $relPath
        $hash1 = (Get-FileHash $path1).Hash
        $hash2 = (Get-FileHash $path2).Hash
        if ($hash1 -ne $hash2) {
            # Content mismatch is important, so we always show it
            Write-Information "DIFFERENT CONTENT: $relPath" -ForegroundColor Yellow
            $differencesFound++
        }
        else {
            # Identical files are hidden unless -Verbose is passed
            Write-Verbose "Identical: $relPath"
        }
    }
    # Summary
    Write-Information "`nComparison complete." -ForegroundColor Cyan
    if ($missingIn1 -or $missingIn2 -or $differencesFound -gt 0) {
        Write-Information "Folders are NOT identical." -ForegroundColor Yellow
    }
    else {
        Write-Information "Folders are completely identical!" -ForegroundColor Green
    }
}
