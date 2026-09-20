<#
✏️ Learn
Invoke-Pester -Container (New-PesterContainer -ScriptBlock { Describe "Test" { It "Pass" { $true | Should -Be $true } } }) -Output None
#>

& ([scriptblock]::Create((oh-my-posh init pwsh --config "/home/nwb/.cache/oh-my-posh/themes/gruvbox.omp.json")))

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
     '-.
        '-. _____
 .-._      |     '.
:  ..      |      :
'-._+      |    .-'
 /  \     .'i--i
/    \ .-'_/____\___
    .-'  :       fsc:
#>

