<#
    .SYNOPSIS
    Shows the effective ClaudeCron settings.

    .DESCRIPTION
    Values come from <root>/config.json, with the module defaults filling any gaps. The
    root itself is $CLAUDE_CRON_HOME if set, otherwise ~/.config/claude-cron.

    .EXAMPLE
    Get-ClaudeCronConfig
#>
function Get-ClaudeCronConfig {
    [CmdletBinding()]
    param ()
    $config = Read-ClaudeCronConfig
    $paths = Get-ClaudeCronPath
    $config | Add-Member -NotePropertyName 'Root' -NotePropertyValue $paths.Root -Force
    $config | Add-Member -NotePropertyName 'ConfigFile' -NotePropertyValue $paths.Config -Force
    $config | Add-Member -NotePropertyName 'ClaudeCommandResolved' -NotePropertyValue (
        (Get-Command -Name $config.ClaudeCommand -ErrorAction SilentlyContinue | Select-Object -First 1).Source
    ) -Force
    return $config
}

<#
    .SYNOPSIS
    Changes ClaudeCron settings and writes them to config.json.

    .PARAMETER ClaudeCommand
    Path to the Claude CLI. Set this to an absolute path when running under cron, whose
    PATH is far shorter than a login shell's.

    .PARAMETER DefaultClaudeArgs
    Arguments used for every prompt job that does not override them. The default,
    --print --permission-mode acceptEdits, is what makes an unattended run possible.

    .PARAMETER PollSeconds
    How often Start-ClaudeCronWorker drains the queue.

    .PARAMETER QuotaResetHours
    Fallback pause length used when the CLI reports a limit without a reset time.

    .PARAMETER JobTimeoutMinutes
    A job running longer than this is killed and recorded with exit code 124.

    .PARAMETER NotifyCommand
    Shell command run when a job finishes or the queue pauses. {title} and {message} are
    substituted, e.g. 'notify-send "{title}" "{message}"'.

    .EXAMPLE
    Set-ClaudeCronConfig -ClaudeCommand /home/nate/.local/bin/claude -PollSeconds 120
#>
function Set-ClaudeCronConfig {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ClaudeCommand,

        [Parameter(Mandatory = $false)]
        [string[]]$DefaultClaudeArgs,

        [Parameter(Mandatory = $false)]
        [string]$DefaultModel,

        [Parameter(Mandatory = $false)]
        [string]$DefaultWorkingDirectory,

        [Parameter(Mandatory = $false)]
        [int]$PollSeconds,

        [Parameter(Mandatory = $false)]
        [int]$QuotaResetHours,

        [Parameter(Mandatory = $false)]
        [int]$MaxAttempts,

        [Parameter(Mandatory = $false)]
        [int]$JobTimeoutMinutes,

        [Parameter(Mandatory = $false)]
        [string]$NotifyCommand
    )
    $config = Read-ClaudeCronConfig
    $settable = @(
        'ClaudeCommand', 'DefaultClaudeArgs', 'DefaultModel', 'DefaultWorkingDirectory',
        'PollSeconds', 'QuotaResetHours', 'MaxAttempts', 'JobTimeoutMinutes', 'NotifyCommand'
    )
    foreach ($key in $settable) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $config | Add-Member -NotePropertyName $key -NotePropertyValue $PSBoundParameters[$key] -Force
        }
    }
    if ($config.DefaultWorkingDirectory -and -not (Test-Path -LiteralPath $config.DefaultWorkingDirectory)) {
        throw "DefaultWorkingDirectory '$($config.DefaultWorkingDirectory)' does not exist."
    }
    if (-not $PSCmdlet.ShouldProcess((Get-ClaudeCronPath).Config, 'Write configuration')) { return }
    Write-ClaudeCronConfig -Config $config | Out-Null
    return Get-ClaudeCronConfig
}
