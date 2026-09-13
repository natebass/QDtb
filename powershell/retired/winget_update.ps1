
# # Display start message
# Write-Host "Starting individual package updates..." -ForegroundColor Magenta
# Write-Host "This might take some time depending on the number of packages and their sizes." -ForegroundColor White
# Write-Host "-----------------------------------------" -ForegroundColor DarkGray

# # Update each package individually
# Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.8" -PackageName ".NET SDK 8"
# Update-WingetPackage -PackageId "Google.AndroidUSBDriverWinusb" -PackageName "ADB & Fastboot Driver"
# # Update-WingetPackage -PackageId "Amazon.AWSCLI" -PackageName "AWS Command Line Interface"
# # Update-WingetPackage -PackageId "Blizzard.BattleNet" -PackageName "Battlenet"
# Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.3_1" -PackageName ".NET Core SDK 3.1"
# Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.5" -PackageName ".NET Core SDK 5.0"
# Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.6" -PackageName ".NET Core SDK 6.0"
# Update-WingetPackage -PackageId "Microsoft.DotNet.SDK.7" -PackageName ".NET Core SDK 7.0"
# Update-WingetPackage -PackageId "Microsoft.VisualStudioCode" -PackageName "Visual Studio Code"
# Update-WingetPackage -PackageId "Microsoft.WindowsTerminal" -PackageName "Windows Terminal"
# Update-WingetPackage -PackageId "Microsoft.PowerShell" -PackageName "PowerShell"
# Update-WingetPackage -PackageId "Git.Git" -PackageName "Git"
# Update-WingetPackage -PackageId "GitHub.GitHubDesktop" -PackageName "GitHub Desktop"
# Update-WingetPackage -PackageId "GitHub.cli" -PackageName "GitHub CLI"
# Update-WingetPackage -PackageId "Google.Chrome" -PackageName "Google Chrome"
# Update-WingetPackage -PackageId "Mozilla.Firefox" -PackageName "Firefox"
# Update-WingetPackage -PackageId "Neovim.Neovim" -PackageName "Neovim"
# Update-WingetPackage -PackageId "OpenJS.NodeJS" -PackageName "Node.js"
# Update-WingetPackage -PackageId "Python.Python.3.12" -PackageName "Python 3.12"
# Update-WingetPackage -PackageId "JanDeDobbeleer.OhMyPosh" -PackageName "Oh My Posh"
# Update-WingetPackage -PackageId "Microsoft.VisualStudio.2022.Community" -PackageName "Visual Studio Community 2022"
# Update-WingetPackage -PackageId "Microsoft.VCRedist.2015+.x64" -PackageName "Microsoft Visual C++ 2015-2022 Redistributable (x64)"
# Update-WingetPackage -PackageId "XP89DCGQ3K6VLD" -PackageName "PowerToys (Preview) x64"
# Update-WingetPackage -PackageId "Microsoft.VCRedist.2015+.x86" -PackageName "Microsoft Visual C++ 2015-2022 Redistributable (x86)"
# Update-WingetPackage -PackageId "GitKraken.cli" -PackageName "GitKraken CLI"
# Update-WingetPackage -PackageId "Postman.Postman" -PackageName "Postman x86_64"
# Update-WingetPackage -PackageId "XP99J3KP4XZ4VV" -PackageName "Zoom Workplace"
# Update-WingetPackage -PackageId "Axosoft.GitKraken" -PackageName "GitKraken"
# Update-WingetPackage -PackageId "Microsoft.Teams.Free" -PackageName "Microsoft Teams (personal)"


# # Display completion message
# Write-Host "Package update process completed!" -ForegroundColor Green
# Write-Host "Note: AWS-related packages were skipped as requested." -ForegroundColor Yellow






# # Not found
# # Update-WingetPackage -PackageId "Google.AndroidStudio.CommandLineTools" -PackageName "Android SDK Command-Line Tools"

# # Suspicious!
# # Update-WingetPackage -PackageId "Amazon.Chime" -PackageName "Amazon Chime"
# # Update-WingetPackage -PackageId "ArduinoSA.IDE.rc" -PackageName "Arduino IDE"
# # Update-WingetPackage -PackageId "AgileBits.1Password" -PackageName "1Password"
# # Update-WingetPackage -PackageId "7zip.7zip" -PackageName "7-Zip"

# # Suspicious not found
# # Update-WingetPackage -PackageId "Amazon.WorkDocs" -PackageName "Amazon WorkDocs"
