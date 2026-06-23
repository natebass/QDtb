

function Start-DocStation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    param()
    if ($PSCmdlet.ShouldProcess('documentation', 'Generate project documentation')) {
        if (Read-LineC468A) {
            Write-Information "Project documentation generated in the $PSScript/docstation folder." -ForegroundColor Green
            return $true
        }
        else {
            Write-Information "You chose no." -ForegroundColor Red
            return $false
        }
    }
    return $false
}

