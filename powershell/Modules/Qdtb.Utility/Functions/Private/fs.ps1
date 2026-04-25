

function DownloadFile {
    <#
    .SYNOPSIS
    Downloads a file from a given URL.

    .SYNOPSIS
    The DownloadFile function takes a file name, URL, and output path, and downloads the file from the specified URL to the given output path.

    .PARAMETER fileName
    The name of the file to be downloaded, used for logging purposes.

    .PARAMETER url
    The URL of the file to be downloaded.

    .PARAMETER outputPath
    The output path where the downloaded file will be saved.

    .EXAMPLE
    DownloadFile -fileName "example.txt" -url "https://example.com/file.txt" -outputPath "C:\Downloads\example.txt"

    .NOTES
    Use Invoke-WebRequest to download the file from the given URL and save it to the specified output path
    Write a message indicating the file has been downloaded
    #>
    [CmdletBinding()]
    param (
        [string]$fileName,
        [string]$url,
        [string]$outputPath
    )
    Invoke-WebRequest -Uri $url -OutFile $outputPath
    Write-Output "Downloaded $fileName to $outputPath"
}
function Remove-Files($path, $pattern, $time = 5) {
    
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
    Write-Host "Removing files from "$path" matching pattern "$pattern" in $time seconds."
    # Countdown
    $time..0 | ForEach-Object { if ($_ -gt 0) { Write-Host $_ }; Start-Sleep -Seconds 1 }
    # Remove matching files
    Get-ChildItem $path | Where-Object { $_.Name -match $pattern } | Remove-Item
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
    Write-Host "Total size of the directory: $totalSizeGB GB"
    $items | Where-Object { $_.PSIsContainer -eq $false } | Sort-Object -Property Length -Descending | Select-Object -First 10 | Format-Table -AutoSize
    # Other
    # Get-ChildItem -Path "C:\Your\Directory\Path" -Recurse | Measure-Object -Property Length -Sum | Format-Table -AutoSize
}