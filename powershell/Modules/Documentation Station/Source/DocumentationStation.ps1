

function Start-DocStation {
    if (Read-LineC468A) {
        Write-Host "Project documentation generated in the $PSScript/docstation folder." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "You chose no." -ForegroundColor Red
        return $false
    }
    return Read-LineC468A
}
