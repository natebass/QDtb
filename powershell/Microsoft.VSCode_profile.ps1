<#
Also check C:\Users\nateb\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_config?view=powershell-7.6
#>

function prompt { Write-RainbowPrompt }
# fnm env --use-on-cd | Out-String | Invoke-Expression

if ($IsWindows) {
  $nvimModulePath = Join-Path $env:LOCALAPPDATA "nvim\powershell\Modules"
}
else {
  $nvimModulePath = "/home/nwb/.var/app/dev.neovide.neovide/config/nvim/powershell/Modules"
}

if (Test-Path $nvimModulePath) {
  $env:PSModulePath = "$nvimModulePath$([System.IO.Path]::PathSeparator)$env:PSModulePath"
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
