# Generate a 1024x1024 pixel grid of random colors
# This script creates a bitmap image with random RGB values for each pixel

Add-Type -AssemblyName System.Drawing

# Set image dimensions
$width = 1024
$height = 1024

# Create a new bitmap
$bitmap = New-Object System.Drawing.Bitmap($width, $height)

# Create a random number generator
$random = New-Object System.Random

Write-Host "Generating $width x $height random color grid..." -ForegroundColor Green

# Generate random colors for each pixel
for ($x = 0; $x -lt $width; $x++) {
    # Show progress every 100 pixels
    if ($x % 100 -eq 0) {
        $progress = [math]::Round(($x / $width) * 100, 1)
        Write-Progress -Activity "Generating random colors" -Status "$progress% Complete" -PercentComplete $progress
    }
    
    for ($y = 0; $y -lt $height; $y++) {
        # Generate random RGB values (0-255)
        $red = $random.Next(0, 256)
        $green = $random.Next(0, 256)
        $blue = $random.Next(0, 256)
        
        # Create color and set pixel
        $color = [System.Drawing.Color]::FromArgb($red, $green, $blue)
        $bitmap.SetPixel($x, $y, $color)
    }
}

# Complete the progress bar
Write-Progress -Activity "Generating random colors" -Completed

# Generate filename with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputPath = "C:\Users\nateb\OneDrive\Documents\PowerShell\Scripts\RandomColorGrid_$timestamp.png"

# Save the image as PNG
try {
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Random color grid saved successfully to: $outputPath" -ForegroundColor Green
    Write-Host "Image size: $width x $height pixels" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to save image: $($_.Exception.Message)"
}
finally {
    # Clean up resources
    $bitmap.Dispose()
}

# Optional: Open the image with default application
$openImage = Read-Host "Would you like to open the generated image? (y/n)"
if ($openImage -eq 'y' -or $openImage -eq 'Y') {
    Start-Process $outputPath
}

