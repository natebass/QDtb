@{
    RootModule           = 'TailwindToCSS.psm1'
    ModuleVersion        = '0.0.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    Author               = 'Nate Bass'
    Copyright            = 'MIT'
    Description          = 'Convert Tailwind classes to CSS.'
    FunctionsToExport    = @(
        "Convert-TailwindToCSS"
    )
    PrivateData          = @{
        PSData = @{
            Tags         = 'Linux', 'PowerShell', 'Tailwind', 'CSS'
            LicenseUri   = 'MIT'
            ProjectUri   = 'https://github.com/natebass/TailwindToCSS'
            IconUri      = 'TailwindToCSS.png'
            ReleaseNotes = "* Initialize project [#1]"
        }
    }
}
