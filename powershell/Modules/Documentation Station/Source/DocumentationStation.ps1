

function Start-DocStation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    param()
    if ($PSCmdlet.ShouldProcess('documentation', 'Generate project documentation')) {
        if (Read-LineC468A) {
            Write-Host "Project documentation generated in the $PSScript/docstation folder." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "You chose no." -ForegroundColor Red
            return $false
        }
    }
    return $false
}

