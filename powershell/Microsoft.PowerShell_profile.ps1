<#
✏️ Learn
Invoke-Pester -Container (New-PesterContainer -ScriptBlock { Describe "Test" { It "Pass" { $true | Should -Be $true } } }) -Output None

Recommendation for a clean and fast terminal experience.
If you want to keep the files in your Neovim config directory without copying them over, you can create a symbolic link from your config directory directly into your user modules folder. This gives you the best of both worlds: instant auto-loading performance, and zero-effort updates when you modify the code.
```bash
ln -s "/home/nwb/.var/app/dev.neovide.neovide/config/nvim/powershell/Modules/Qdtb.Utility" "/home/nwb/.local/share/powershell/Modules/Qdtb.Utility"
```
#>
& ([scriptblock]::Create((oh-my-posh init pwsh --config "/home/nwb/.cache/oh-my-posh/themes/gruvbox.omp.json")))

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
