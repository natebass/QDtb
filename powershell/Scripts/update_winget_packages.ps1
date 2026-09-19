<#
.SYNOPSIS
    Script to individually update all installed winget packages.

.DESCRIPTION
    This PowerShell script updates each winget package individually.
    AWS-related packages are commented out as requested.
    Error handling is included to ensure the script continues even if a package update fails.

.NOTES
    Author: Nate
    Date: Created based on current winget package list
#>

# Update-WingetPackage is exported by QDtb.Utility. It used to be defined here as
# well, and the two copies had drifted, so whichever loaded last decided the behaviour.
# Import by path so this script uses the copy in this repository either way.
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../Modules/QDtb.Utility/QDtb.Utility.psd1') -Force

# Display start message
Write-Host "Starting individual package updates..." -ForegroundColor Magenta
Write-Host "This might take some time depending on the number of packages and their sizes." -ForegroundColor White
Write-Host "-----------------------------------------" -ForegroundColor DarkGray

# Update each package individually
Update-WingetPackage -PackageId "AgileBits.1Password" -PackageName "1Password"
Update-WingetPackage -PackageId "7zip.7zip" -PackageName "7-Zip"
Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.8" -PackageName ".NET SDK 8"
Update-WingetPackage -PackageId "Google.AndroidUSBDriverWinusb" -PackageName "ADB & Fastboot Driver"
Update-WingetPackage -PackageId "Amazon.Chime" -PackageName "Amazon Chime"
# Update-WingetPackage -PackageId "Amazon.AWSCLI" -PackageName "AWS Command Line Interface"
Update-WingetPackage -PackageId "Amazon.WorkDocs" -PackageName "Amazon WorkDocs"
Update-WingetPackage -PackageId "Google.AndroidStudio.CommandLineTools" -PackageName "Android SDK Command-Line Tools"
Update-WingetPackage -PackageId "ArduinoSA.IDE.rc" -PackageName "Arduino IDE"
Update-WingetPackage -PackageId "Blizzard.BattleNet" -PackageName "Battlenet"
Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.3_1" -PackageName ".NET Core SDK 3.1"
Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.5" -PackageName ".NET Core SDK 5.0"
Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.6" -PackageName ".NET Core SDK 6.0"
Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.7" -PackageName ".NET Core SDK 7.0"
Update-WingetPackage -PackageId "Microsoft.VisualStudioCode" -PackageName "Visual Studio Code"
Update-WingetPackage -PackageId "Microsoft.WindowsTerminal" -PackageName "Windows Terminal"
Update-WingetPackage -PackageId "Microsoft.PowerShell" -PackageName "PowerShell"
Update-WingetPackage -PackageId "Git.Git" -PackageName "Git"
Update-WingetPackage -PackageId "GitHub.GitHubDesktop" -PackageName "GitHub Desktop"
Update-WingetPackage -PackageId "GitHub.cli" -PackageName "GitHub CLI"
Update-WingetPackage -PackageId "Google.Chrome" -PackageName "Google Chrome"
Update-WingetPackage -PackageId "Mozilla.Firefox" -PackageName "Firefox"
Update-WingetPackage -PackageId "Neovim.Neovim" -PackageName "Neovim"
Update-WingetPackage -PackageId "OpenJS.NodeJS" -PackageName "Node.js"
Update-WingetPackage -PackageId "Python.Python.3.12" -PackageName "Python 3.12"
Update-WingetPackage -PackageId "JanDeDobbeleer.OhMyPosh" -PackageName "Oh My Posh"

# Display completion message
Write-Host "Package update process completed!" -ForegroundColor Green
Write-Host "Note: AWS-related packages were skipped as requested." -ForegroundColor Yellow


