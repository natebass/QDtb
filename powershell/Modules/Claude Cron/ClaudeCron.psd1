@{
    RootModule           = 'ClaudeCron.psm1'
    ModuleVersion        = '1.1.0'
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
1.1.0
* The crontab installers abandon the install if `crontab -l` fails for any reason other
  than an absent crontab, instead of replacing the user's crontab with their own block.
* The cron entry escapes `%`, rejects a line break in PATH, and pins CLAUDE_CRON_HOME so
  the scheduler drains the same queue an interactive shell sees.
* The systemd service sets TimeoutStartSec=infinity; the 90 second default was killing
  any run longer than that, well inside JobTimeoutMinutes.
* NotifyCommand receives {title} and {message} as shell arguments, so a job name
  containing shell syntax can no longer be executed.
* Quota and sign-out detection reads stderr and the tail of stdout rather than the whole
  transcript, and no longer treats a bare 429, 401 or "unauthorized" in prose as a
  reason to pause the queue for five hours.
* The worker lock is created with CreateNew and records the owner's start time, closing
  the race between two drains and the pid-reuse deadlock after a reboot.
* A job left Running by a killed worker is returned to the queue on the next drain.
* config.json, state.json and job files are written atomically.
* claude-cron.log rotates at MaxLogSizeMB; an idle drain no longer logs at INFO.
* Clear-ClaudeCronQueue removes the cleared jobs' logs unless -KeepLog is given, and
  history.jsonl records every run of a repeating job rather than only its last.

1.0.0
* Queue prompts and commands with -At, -Every and -Cron scheduling.
* Detects AI quota exhaustion, pauses the queue and resumes at the reset.
* crontab and systemd user timer installers.
'@
        }
    }
}

