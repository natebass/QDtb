# Change these paths to your SVG input file and your desired ICO output file location.
$InputSvg = "C:\Users\nateb\Downloads\logo-blue.svg"
$OutputIco = "C:\Users\nateb\Downloads\logo-blue.ico"

# Define the sizes to include in the ICO file
# These are the recommended sizes for Windows
$IcoSizes = "16,32,48,256"
# Check for ImageMagick (magick.exe)
if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
    Write-Host "Error: ImageMagick 'magick.exe' is not found. Please install it." -ForegroundColor Red
    Write-Host "Download from: https://imagemagick.org/index.php" -ForegroundColor Cyan
    exit
}
# Use ImageMagick to convert the SVG to an ICO with multiple sizes
# The `icon:auto-resize` define automatically generates icons for the specified sizes
# and includes them in the single ICO container file.
Write-Host "Converting '$InputSvg' to '$OutputIco'..." -ForegroundColor Yellow
magick $InputSvg -define "icon:auto-resize=$IcoSizes" $OutputIco
# Check if the conversion was successful
if (Test-Path $OutputIco) {
    Write-Host "Success! The ICO file was created at '$OutputIco'." -ForegroundColor Green
    
}
else {
    Write-Host "Conversion failed. Please check your ImageMagick installation and file paths." -ForegroundColor Red
}

