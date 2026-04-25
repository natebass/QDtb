<#
    .SYNOPSIS
        Writes 3 right chevrons (>>>) in rainbow colors.
#>
function Write-RainbowPrompt {
    param (
        [string]$platform = [Environment]::OSVersion.Platform
    )
    switch ($platform) {
        'Unix' {
            write-host "❯" -NoNewline -ForegroundColor DarkRed
            write-host "❯" -NoNewline -ForegroundColor Green
            write-host "❯ " -NoNewline -ForegroundColor Magenta
            # write-host " " -NoNewline
        }
        default {
            # $currentUser = [Environment]::UserName
            # $currentDirectory = Get-Location
            # write-host "$currentUser" -NoNewline -ForegroundColor DarkGray
            # write-host " $currentDirectory " -NoNewline -ForegroundColor DarkBlue
            # write-host ""
            write-host ">" -NoNewline -ForegroundColor DarkRed
            write-host ">" -NoNewline -ForegroundColor Green
            write-host ">" -NoNewline -ForegroundColor Magenta
            write-host " " -NoNewline
        }
    }
}
<#
    .SYNOPSIS
        Writes a table of all possible foreground and background colors.
#>
function Write-ColorTable {
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|"  -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}