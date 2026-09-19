<#
    Shared sandbox for the module test suites.

    A test is hermetic when its result depends on nothing but the code under test: not on
    the working directory it was started from, not on the machine's crontab or home
    directory, and not on a network or a person being there to press a key. These helpers
    give each suite somewhere disposable to work so that stays true.

    The suites in this repository needed it for a specific reason: several of the modules
    write to paths relative to the current directory - 'script.log', 'icon/' - so running
    their tests used to litter whatever folder Invoke-Pester happened to be started from.
#>

<#
    .SYNOPSIS
    Creates a disposable directory, makes it the working directory, and isolates HOME.

    .DESCRIPTION
    Returns the sandbox path, which the caller hands back to Remove-PesterSandbox. HOME
    and the XDG variables are redirected into the sandbox so a module that resolves a
    path under the home directory writes there instead of the real one.

    .PARAMETER Name
    A short label used in the directory name, so a sandbox left behind by an interrupted
    run says which suite it came from.
#>
function New-PesterSandbox {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Creates a disposable temp directory for a test run.')]
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    $path = Join-Path ([System.IO.Path]::GetTempPath()) "pester-$Name-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
    New-Item -ItemType Directory -Path $path -Force | Out-Null

    $sandbox = [pscustomobject]@{
        Path     = $path
        Home     = Join-Path $path 'home'
        Previous = [ordered]@{
            HOME            = $env:HOME
            USERPROFILE     = $env:USERPROFILE
            XDG_CONFIG_HOME = $env:XDG_CONFIG_HOME
            XDG_DATA_HOME   = $env:XDG_DATA_HOME
        }
    }
    New-Item -ItemType Directory -Path $sandbox.Home -Force | Out-Null

    $env:HOME = $sandbox.Home
    $env:USERPROFILE = $sandbox.Home
    $env:XDG_CONFIG_HOME = Join-Path $sandbox.Home '.config'
    $env:XDG_DATA_HOME = Join-Path $sandbox.Home '.local/share'

    # Anything the code under test writes relative to the current directory lands here.
    Push-Location -LiteralPath $path
    return $sandbox
}

<#
    .SYNOPSIS
    Restores the working directory and environment, and deletes the sandbox.

    .DESCRIPTION
    Safe to call on a sandbox that is already gone, so it can sit in an AfterAll that runs
    after a failure.
#>
function Remove-PesterSandbox {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Removes only the disposable temp directory it was given.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [psobject]$Sandbox
    )
    if ($null -eq $Sandbox) { return }

    Pop-Location -ErrorAction SilentlyContinue
    foreach ($entry in $Sandbox.Previous.GetEnumerator()) {
        Set-Item -Path "env:$($entry.Key)" -Value $entry.Value -ErrorAction SilentlyContinue
    }

    # Refuse to delete anything that is not the temp directory this module made, so a
    # mangled path can never turn cleanup into data loss.
    $temp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $target = [System.IO.Path]::GetFullPath($Sandbox.Path)
    if ($target.StartsWith($temp) -and (Split-Path $target -Leaf).StartsWith('pester-')) {
        Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Warning "Refusing to remove '$target': it is not a sandbox this module created."
    }
}

Export-ModuleMember -Function 'New-PesterSandbox', 'Remove-PesterSandbox'

