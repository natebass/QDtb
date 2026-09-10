# Grab the configuration values from the manifest
$macroSettings = $ExecutionContext.SessionState.Module.PrivateData

# Store them as a module-scoped variable so all functions can see them
$script:DefaultPath = $macroSettings.DefaultDownloadPath
$script:MaxDownloads = $macroSettings.MaxConcurrentDownloads

# Load your functions next. Private first: Save-RSSEpisode is built out of the helpers
# in Source/Private, which this used to skip entirely.
foreach ($scope in @('Private', 'Public')) {
    $folder = Join-Path $PSScriptRoot 'Source' $scope
    if (-not (Test-Path -LiteralPath $folder)) { continue }
    foreach ($file in (Get-ChildItem -LiteralPath $folder -Filter '*.ps1' -File -Recurse -Exclude '*.Tests.ps1' | Sort-Object FullName)) {
        . $file.FullName
    }
}
