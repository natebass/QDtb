# Grab the configuration values from the manifest
$macroSettings = $ExecutionContext.SessionState.Module.PrivateData

# Store them as a module-scoped variable so all functions can see them
$script:DefaultPath = $macroSettings.DefaultDownloadPath
$script:MaxDownloads = $macroSettings.MaxConcurrentDownloads

# Load your functions next
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot\Source\Public\*.ps1" -Recurse)) {
    . $file.FullName
}
