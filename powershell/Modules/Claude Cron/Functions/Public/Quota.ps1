<#
    .SYNOPSIS
    Shows whether the queue is paused waiting for the AI quota to reset.

    .EXAMPLE
    Get-ClaudeCronQuota
#>
function Get-ClaudeCronQuota {
    [CmdletBinding()]
    param ()
    $state = Read-ClaudeCronState
    $blockedUntil = ConvertFrom-ClaudeCronTimestamp $state.BlockedUntil
    $remaining = if ($blockedUntil -and $blockedUntil -gt (Get-Date)) { $blockedUntil - (Get-Date) } else { [timespan]::Zero }
    return [pscustomobject]@{
        Blocked      = ($remaining -gt [timespan]::Zero)
        BlockedUntil = $blockedUntil
        Remaining    = $remaining
        BlockedBy    = $state.BlockedBy
        BlockedAt    = ConvertFrom-ClaudeCronTimestamp $state.BlockedAt
    }
}

<#
    .SYNOPSIS
    Pauses the queue by hand until a quota reset you already know about.

    .DESCRIPTION
    The runner sets this on its own when the CLI reports a limit. Set it yourself when
    you hit the limit in an interactive session and want the queue to wait too.

    .PARAMETER Until
    The moment the quota comes back, such as '18:00'.

    .PARAMETER In
    A duration from now instead of a wall clock time: 5h, 90m.

    .EXAMPLE
    Set-ClaudeCronQuota -In 5h

    .EXAMPLE
    Set-ClaudeCronQuota -Until '18:00'
#>
function Set-ClaudeCronQuota {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Until')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Until', Position = 0)]
        [datetime]$Until,

        [Parameter(Mandatory = $true, ParameterSetName = 'In')]
        [string]$In,

        [Parameter(Mandatory = $false)]
        [string]$Reason = 'set by hand'
    )
    $moment = if ($PSCmdlet.ParameterSetName -eq 'In') {
        (Get-Date).Add((ConvertTo-ClaudeCronTimeSpan -Interval $In))
    }
    else {
        $Until
    }
    if (-not $PSCmdlet.ShouldProcess($moment.ToString('yyyy-MM-dd HH:mm'), 'Pause queue until')) { return }

    $state = Read-ClaudeCronState
    $state.BlockedUntil = ConvertTo-ClaudeCronTimestamp $moment
    $state.BlockedBy = $Reason
    $state.BlockedAt = ConvertTo-ClaudeCronTimestamp (Get-Date)
    Write-ClaudeCronState -State $state | Out-Null
    Write-ClaudeCronLog -Level 'INFO' -Message "Queue paused until $($moment.ToString('yyyy-MM-dd HH:mm')) ($Reason)."
    return Get-ClaudeCronQuota
}

<#
    .SYNOPSIS
    Lifts a quota pause so the next drain runs immediately.

    .EXAMPLE
    Clear-ClaudeCronQuota
#>
function Clear-ClaudeCronQuota {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()
    if (-not $PSCmdlet.ShouldProcess('quota block', 'Clear')) { return }
    $state = Read-ClaudeCronState
    $state.BlockedUntil = $null
    $state.BlockedBy = $null
    $state.BlockedAt = $null
    Write-ClaudeCronState -State $state | Out-Null
    Write-ClaudeCronLog -Level 'INFO' -Message 'Quota block cleared.'
    return Get-ClaudeCronQuota
}
