
@{
    RootModule           = 'QDtb.Utility.psm1'
    ModuleVersion        = '1.0.0'
    CompatiblePSEditions = 'Core', 'Desktop'
    GUID                 = '4020b9a6-2cf9-4e37-990a-aadb1747baba'
    Author               = 'Nate Bass'
    Copyright            = 'MIT'
    Description          = 'General utility functions.'
    PowerShellVersion    = '5.1'
    FunctionsToExport    = @(
        "Write-RainbowPrompt"
        "Start-MyProject"
        "Sync-Fork"
        "Get-MyProjectGitStatus"
        "ConvertTo-Icon"
        "New-RandomColorGridImage"
        "Update-WingetPackage"
        "Update-GitRepositories"
        "Invoke-GitStatusCheck"
    )
    CmdletsToExport      = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'Linux', 'PowerShell'

            # A URL to the license for this module.
            LicenseUri   = ''

            # A URL to the main website for this project.
            ProjectUri   = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = "* Initialize project [#1]"
        }
    }
}
