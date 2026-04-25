
BeforeAll {
    $appmodulepath = Resolve-Path $PSScriptRoot/../DocumentationStation.psd1
    Import-Module "$appmodulepath"
}

Describe "a Tests" {
    It "Should return a" {
        $result = Start-DocStation
        write-host $result
        $result | Should -Contain 'a'
    }
}

# Describe "PSReadLine Key Handler Tests" {
#     It "Should set a new key handler successfully" {
#         Set-PSReadLineKeyHandler -Key 'Ctrl+x' -Function p
#         $result = Get-PSReadLineKeyHandler
#         $result | Should -Contain 'Ctrl+x'
#     }
# }

# Describe "Custom key bindings tests" {
#     It "Should set a new key binding successfully" {
#         Example-Keybinding
#     }
# }


# Example.ps1
# Import-Module Resolve-Path $PSScriptRoot/../DocumentationStation.psd1
# # Example-Keybinding
# # Get-PSReadLineKeyHandler
# # Read-LineC468A

# write-host $PSScriptRoot

# Start-DocStation
