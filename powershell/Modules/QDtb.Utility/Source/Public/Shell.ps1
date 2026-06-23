<#
    .SYNOPSIS
        Writes 3 right chevrons (>>>) in rainbow colors.
#>
function Write-RainbowPrompt {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        [string]$platform = [Environment]::OSVersion.Platform
    )
    switch ($platform) {
        'Unix' {
            Write-Host "❯" -NoNewline -ForegroundColor DarkRed
            Write-Host "❯" -NoNewline -ForegroundColor Green
            Write-Host "❯ " -NoNewline -ForegroundColor Magenta
            # Write-Host " " -NoNewline
        }
        default {
            # $currentUser = [Environment]::UserName
            # $currentDirectory = Get-Location
            # Write-Host "$currentUser" -NoNewline -ForegroundColor DarkGray
            # Write-Host " $currentDirectory " -NoNewline -ForegroundColor DarkBlue
            # Write-Host ""
            Write-Host ">" -NoNewline -ForegroundColor DarkRed
            Write-Host ">" -NoNewline -ForegroundColor Green
            Write-Host ">" -NoNewline -ForegroundColor Magenta
            Write-Host " " -NoNewline
        }
    }
}

<#
    .SYNOPSIS
        Writes a table of all possible foreground and background colors.
#>
function Write-ColorTable {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param()
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|"  -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}
