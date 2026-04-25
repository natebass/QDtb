
Import-Module "/home/nwb/.local/share/powershell/Modules/Qdtb.SvgToReact/SvgToReact.psd1"
Import-Module "/home/nwb/.local/share/powershell/Modules/Qdtb.Utility/DiosTeB.psd1"

<#
Also check C:\Users\nateb\OneDrive\Documents\WindowsPowerShell\Microsoft.VSCode_profile.ps1
#>
function prompt { Write-RainbowPrompt }
# fnm env --use-on-cd | Out-String | Invoke-Expression
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
<#
           ___
     |     | |
    / \    | |
   |--o|===|-|
   |---|   |d|
  /     \  |w|
 | U     | |b|
 | S     |=| |
 | A     | | |
 |_______| |_|
  |@| |@|  | |
___________|_|_
#>
