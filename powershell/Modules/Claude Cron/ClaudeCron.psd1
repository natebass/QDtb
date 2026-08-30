@{
    RootModule           = 'ClaudeCron.psm1'
    ModuleVersion        = '1.0.0'
    CompatiblePSEditions = 'Core'
    GUID                 = 'ad8c9dc4-7f4a-43f6-b59d-49cfb5127977'
    Author               = 'Nate Bass'
    Copyright            = 'MIT'
    Description          = 'Queue Claude prompts and shell commands to run at a time, on an interval, or as soon as the AI quota resets.'
    PowerShellVersion    = '7.2'
    FunctionsToExport    = @(
        # Queue
        'Add-ClaudeCronPrompt'
        'Add-ClaudeCronCommand'
        'Get-ClaudeCronJob'
        'Set-ClaudeCronJob'
        'Remove-ClaudeCronJob'
        'Clear-ClaudeCronQueue'
        'Get-ClaudeCronLog'
        # Running
        'Invoke-ClaudeCronQueue'
        'Start-ClaudeCronWorker'
        'Get-ClaudeCronStatus'
        # Quota
        'Get-ClaudeCronQuota'
        'Set-ClaudeCronQuota'
        'Clear-ClaudeCronQuota'
        # Configuration and scheduling
        'Get-ClaudeCronConfig'
        'Set-ClaudeCronConfig'
        'Get-ClaudeCronSchedule'
        'Get-ClaudeCronDrainCommand'
        'Install-ClaudeCronSchedule'
        'Uninstall-ClaudeCronSchedule'
        'Install-ClaudeCronTimer'
        'Uninstall-ClaudeCronTimer'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @(
        'ccq'
        'ccadd'
        'ccrun'
    )
    PrivateData          = @{
        PSData = @{
            Tags         = 'Linux', 'PowerShell', 'Claude', 'Cron', 'Queue', 'Automation'
            LicenseUri   = ''
            ProjectUri   = ''
            ReleaseNotes = @'
1.0.0
* Queue prompts and commands with -At, -Every and -Cron scheduling.
* Detects AI quota exhaustion, pauses the queue and resumes at the reset.
* crontab and systemd user timer installers.
'@
        }
    }
}
