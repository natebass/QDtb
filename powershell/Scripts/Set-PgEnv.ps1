# 1. Inspect existing environment variables
Write-Host "Checking for common PostgreSQL environment variables:"

$pgVars = [ordered]@{
    PGUSER     = $env:PGUSER
    PGPASSWORD = if ($env:PGPASSWORD) { "[Set - Hidden]" } else { $null }
    PGDATABASE = $env:PGDATABASE
    PGHOST     = $env:PGHOST
    PGPORT     = $env:PGPORT
}

foreach ($var in $pgVars.GetEnumerator()) {
    $displayValue = if ([string]::IsNullOrWhiteSpace($var.Value)) { "[Not Set]" } else { $var.Value }
    Write-Host ("  {0,-11} {1}" -f "$($var.Key):", $displayValue)
}

Write-Host ""

# 2. Interactive prompt for new values
Write-Host "Setting common PostgreSQL environment variables:"

$inputUser     = Read-Host -Prompt "Enter PGUSER"
$inputPassword = Read-Host -Prompt "Enter PGPASSWORD" -AsSecureString
$inputDb       = Read-Host -Prompt "Enter PGDATABASE"
$inputHost     = Read-Host -Prompt "Enter PGHOST [localhost]"
$inputPort     = Read-Host -Prompt "Enter PGPORT [5432]"

# 3. Apply defaults if optional fields were left blank
if ([string]::IsNullOrWhiteSpace($inputHost)) { $inputHost = "localhost" }
if ([string]::IsNullOrWhiteSpace($inputPort)) { $inputPort = "5432" }

# Convert SecureString password to plain text for $env:PGPASSWORD
$plainPassword = [System.Net.NetworkCredential]::new("", $inputPassword).Password

# 4. Export globally to the current shell environment
$env:PGUSER     = $inputUser
$env:PGPASSWORD = $plainPassword
$env:PGDATABASE = $inputDb
$env:PGHOST     = $inputHost
$env:PGPORT     = $inputPort

Write-Host "`nPostgreSQL environment variables updated for current session."