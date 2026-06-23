
<#
.SYNOPSIS
    Converts WebP images to PNG format.

.SYNOPSIS
    This script converts all `.webp` files in the specified input directory to `.png` format and saves them to the specified output directory.

.PARAMETER inputDir
    The path to the directory containing `.webp` files. Default is "/home/nwb/Downloads".

.PARAMETER outputDir
    The path to the directory where `.png` files will be saved. Default is "/home/nwb/Downloads".

.EXAMPLE
    Convert-WebpToPng -inputDir "/path/to/your/webp/files" -outputDir "/path/to/save/png/files"

.EXAMPLE
    Convert-WebpToPng
    Converts files in the default directory "/home/nwb/Downloads".

#>
function Convert-WebpToPng {
    param (
        [string]$inputDir = "/home/nwb/Downloads",
        [string]$outputDir = "/home/nwb/Downloads"
    )
    # Ensure output directory exists
    if (!(Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir
    }
    # Loop through each .webp file in the input directory
    Get-ChildItem -Path $inputDir -Filter *.webp | ForEach-Object {
        $inputFile = $_.FullName
        $outputFile = Join-Path -Path $outputDir -ChildPath "$($_.BaseName).png"
        # Use ImageMagick's "magick" command to convert webp to png
        convert $inputFile $outputFile
    }
    Write-Information "Conversion complete!"
}
<#
.SYNOPSIS
    Edits the icon for CopyQ on Linux Mint by resizing it to multiple standard icon sizes.

.SYNOPSIS
    This function takes an input image file, typically an icon, and resizes it to multiple commonly used icon sizes for Linux Mint.
    The resized icons are saved in the appropriate directories within `/usr/share/icons/hicolor`.

.PARAMETER input_file
    The path to the input image file to be resized. Default is "/home/nwb/Downloads/birdcropflip.png".

.PARAMETER base_output_dir
    The base directory where resized icons will be saved. Default is "/usr/share/icons/hicolor".

.EXAMPLE
    Edit-LinuxMintIconCopyQ
    Resizes the default icon file `/home/nwb/Downloads/birdcropflip.png` and saves resized copies to `/usr/share/icons/hicolor`.
.NOTES
    Alternate solution
    ```powershell
        # $files = @("/usr/share/icons/hicolor/128x128/apps/copyq.png",
        #     "/usr/share/icons/hicolor/16x16/apps/copyq.png",
        #     "/usr/share/icons/hicolor/22x22/apps/copyq.png",
        #     "/usr/share/icons/hicolor/24x24/apps/copyq.png",
        #     "/usr/share/icons/hicolor/32x32/apps/copyq.png",
        #     "/usr/share/icons/hicolor/48x48/apps/copyq.png",
        #     "/usr/share/icons/hicolor/64x64/apps/copyq.png")

        # foreach ($file in $files) {
        #     Rename-Item $file -NewName ($file + "_backup")
        # }
    ```
    #>
function Edit-LinuxMintIconCopyQ {
    # Define the input file path and base output directory
    $input_file = "/home/nwb/Downloads/birdcropflip.png"
    # $input_file = "/usr/share/icons/hicolor/scalable/apps/copyq_mask.svg"
    $base_output_dir = "/usr/share/icons/hicolor"
    # Define the desired sizes
    $sizes = @(16, 22, 24, 32, 48, 64, 128)
    # Iterate through the sizes and resize the image
    foreach ($size in $sizes) {
        $output_dir = Join-Path $base_output_dir ("$size" + "x" + "$size")
        $output_file = Join-Path $output_dir "apps/copyq.png"
        # Create the output directory if it doesn't exist
        if (!(Test-Path $output_dir)) {
            New-Item -ItemType Directory -Path $output_dir
        }
        # Use ImageMagick to resize and convert the image. Requires ImageMagick to be installed.
        convert -resize "${size}x${size}" -background none "$input_file" "$output_file"
    }
}
