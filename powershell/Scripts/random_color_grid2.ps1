<#
.SYNOPSIS
    Demonstrates how to use the RandomColorGrid module to generate an image.

.DESCRIPTION
    This script imports the RandomColorGrid module and calls the New-RandomColorGridImage
    function with various parameters.

.NOTES
    Author: Your Name
    Date: August 1, 2025
#>

# Get the directory of the current script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Define the path to your module
$modulePath = Join-Path $scriptDir "RandomColorGrid.psm1"

# Import the module
Write-Host "Attempting to import module from: $modulePath"
try {
    Import-Module $modulePath -ErrorAction Stop
    Write-Host "Module 'RandomColorGrid' imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to import module: $_"
    exit 1
}

# --- Examples of using the function ---

# 1. Generate an image with default settings (254x254, RandomColorGrid.png in current directory)
Write-Host "`n--- Example 1: Default Settings ---`n"
New-RandomColorGridImage

# 2. Generate a smaller image with a custom name
Write-Host "`n--- Example 2: Custom Size and Name ---`n"
$customImagePath1 = Join-Path $scriptDir "SmallRandomGrid.png"
New-RandomColorGridImage -Width 100 -Height 100 -OutputPath $customImagePath1

# 3. Generate a larger image in a specific subfolder (ensure folder exists)
Write-Host "`n--- Example 3: Larger Image in Subfolder ---`n"
$outputSubFolder = Join-Path $scriptDir "GeneratedImages"
if (-not (Test-Path $outputSubFolder -PathType Container)) {
    Write-Host "Creating output folder: $outputSubFolder"
    New-Item -ItemType Directory -Path $outputSubFolder | Out-Null
}
$customImagePath2 = Join-Path $outputSubFolder "LargeRandomGrid.png"
New-RandomColorGridImage -Width 500 -Height 500 -OutputPath $customImagePath2

Write-Host "`n--- Script Finished ---`n"
