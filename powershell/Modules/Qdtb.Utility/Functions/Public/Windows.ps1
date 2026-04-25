function Update-WingetPackage {
    <#
    .SYNOPSIS
        Script to individually update all installed winget packages.

    .DESCRIPTION
        This PowerShell script updates each winget package individually.
        AWS-related packages are commented out as requested.
        Error handling is included to ensure the script continues even if a package update fails.

    .NOTES
        Author: Nate
        Date: Created based on current winget package list
    #>
    param (
        [string]$PackageId,
        [string]$PackageName
    )
    
    Write-Host "Attempting to update $PackageName ($PackageId)..." -ForegroundColor Cyan
    
    try {
        # Run winget upgrade with the package ID
        winget upgrade --id $PackageId --exact
        
        # Check if the update was successful
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully updated $PackageName" -ForegroundColor Green
        }
        elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Host "No applicable update found for $PackageName" -ForegroundColor Yellow
        }
        else {
            Write-Host "Update failed for $PackageName with exit code: $LASTEXITCODE" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error updating $PackageName $_" -ForegroundColor Red
    }
    
    # Add a separator line for readability
    Write-Host "-----------------------------------------" -ForegroundColor DarkGray
}

<#
.SYNOPSIS
    Creates a PNG image with random colored pixels.

.DESCRIPTION
    This function generates a bitmap of specified dimensions, fills each pixel with a random color,
    and saves the result as a PNG file.

.PARAMETER Width
    The width of the image in pixels. Defaults to 254.

.PARAMETER Height
    The height of the image in pixels. Defaults to 254.

.PARAMETER OutputPath
    The full path, including the filename and extension, where the PNG image will be saved.
    Defaults to 'RandomColorGrid.png' in the current directory if not specified.

.NOTES
    Author: Nate Bass
    Date: June 3, 2025
    Updated: August 1, 2025 (Converted to module)
#>
function New-RandomColorGridImage {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Width = 254,

        [Parameter(Mandatory = $false)]
        [int]$Height = 254,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path $PSScriptRoot "RandomColorGrid.png")
    )

    # Add System.Drawing assembly
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to load System.Drawing assembly. This module requires .NET Framework/Core."
        return
    }

    $bitmap = $null # Initialize to null for finally block
    try {
        # Create a new bitmap
        $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)

        # Create a random number generator
        $random = New-Object System.Random

        Write-Host "Generating random color grid ($Width x $Height)..."

        for ($x = 0; $x -lt $Width; $x++) {
            # Show progress every 25 rows
            if ($x % 25 -eq 0) {
                Write-Progress -Activity "Creating random color grid" -Status "Processing rows..." -PercentComplete (($x / $Width) * 100)
            }

            for ($y = 0; $y -lt $Height; $y++) {
                # Generate random RGB values
                $r = $random.Next(0, 256)
                $g = $random.Next(0, 256)
                $b = $random.Next(0, 256)

                # Create color and set pixel
                $color = [System.Drawing.Color]::FromArgb($r, $g, $b)
                $bitmap.SetPixel($x, $y, $color)
            }
        }
        Write-Progress -Activity "Creating random color grid" -Status "Processing complete." -PercentComplete 100 -Completed

        # Resolve output path relative to the caller's script if $PSScriptRoot isn't available in module scope
        # If the OutputPath isn't explicitly set by the user, we want it to be relative to where the module is *imported* from,
        # or just the current working directory if imported directly.
        if ($MyInvocation.BoundParameters.ContainsKey('OutputPath')) {
            # OutputPath was explicitly provided, use it as is.
            $finalOutputPath = $OutputPath
        }
        else {
            # OutputPath was not provided, use default relative to the script that calls this function.
            # If called directly from console, it will be relative to current directory.
            $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
            if ([string]::IsNullOrEmpty($scriptRoot) -or $scriptRoot -eq $PSScriptRoot) {
                # If invoked from within the module file itself or just directly loaded without a calling script context
                $finalOutputPath = Join-Path (Get-Location) "RandomColorGrid.png"
            }
            else {
                # Invoked from a separate script
                $finalOutputPath = Join-Path $scriptRoot "RandomColorGrid.png"
            }
        }

        Write-Host "Saving image to $finalOutputPath..."
        $bitmap.Save($finalOutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

        Write-Host "Image created successfully!" -ForegroundColor Green
        Write-Host "Image saved to: $finalOutputPath"
        return $finalOutputPath # Return the path for potential further use
    }
    catch {
        Write-Error "An error occurred while creating the image: $_"
    }
    finally {
        # Clean up resources
        if ($bitmap -ne $null) {
            $bitmap.Dispose()
            $bitmap = $null
        }
    }
}

function ConvertTo-Icon {
    <#
    .SYNOPSIS
    Converts an image or SVG file to an ICO file.
    Provides verbose output for better debugging.

    .DESCRIPTION
    This function takes an image file (e.g., PNG, JPG, BMP) or an SVG file
    and converts it into a Windows Icon (.ico) file.
    For SVG files, it requires Inkscape to be installed and available in your PATH
    to first convert the SVG to a temporary PNG.

    .PARAMETER File
    The path to the source image or SVG file.

    .PARAMETER OutputFile
    The desired path for the output ICO file.

    .EXAMPLE
    ConvertTo-Icon2 -File "C:\path\to\myimage.png" -OutputFile "C:\path\to\myicon.ico" -Verbose

    .EXAMPLE
    ConvertTo-Icon2 -File "C:\path\to\mylogo.svg" -OutputFile "$HOME\Downloads\mylogo.ico" -Verbose

    .NOTES
    Requires Inkscape for SVG conversion.
    Uses System.Drawing assembly for image processing and ICO creation.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$File,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$OutputFile
    )

    # Set ErrorActionPreference to 'Stop' to catch terminating errors within the try block
    $ErrorActionPreference = 'Stop'

    # --- DEBUGGING START ---
    Write-Host "DEBUG: Function started."
    Write-Verbose "Starting conversion process for file: '$File' to '$OutputFile'."
    # --- DEBUGGING END ---

    # Validate input file existence
    if (-not (Test-Path $File -PathType Leaf)) {
        Write-Error "Error: Input file '$File' not found."
        Write-Host "DEBUG: Input file check failed. Returning."
        return
    }
    Write-Verbose "Input file '$File' found."

    # Ensure the output directory exists
    $outputDir = Split-Path $OutputFile -Parent
    if (-not (Test-Path $outputDir -PathType Container)) {
        Write-Verbose "Output directory '$outputDir' does not exist. Attempting to create it."
        try {
            New-Item -ItemType Directory -Path $outputDir -ErrorAction Stop | Out-Null
            Write-Verbose "Output directory '$outputDir' created successfully."
        }
        catch {
            Write-Error "Error: Could not create output directory '$outputDir'. $($_.Exception.Message)"
            Write-Host "DEBUG: Output directory creation failed. Returning."
            return
        }
    }
    Write-Verbose "Output directory '$outputDir' verified/created."

    # Initialize variables for image paths and disposal
    $pngPath = $null
    $tmpPngCreated = $false
    $img = $null
    $bmp = $null
    $icon = $null
    $fs = $null

    try {
        # --- DEBUGGING START ---
        Write-Host "DEBUG: Entering main try block."
        # --- DEBUGGING END ---

        # Get file extension and convert SVG if necessary
        $ext = [System.IO.Path]::GetExtension($File).ToLowerInvariant()

        if ($ext -eq '.svg') {
            Write-Verbose "Input file is an SVG. Attempting to convert to PNG using Inkscape."
            $inkscapeCmd = Get-Command inkscape -ErrorAction SilentlyContinue
            if (-not $inkscapeCmd) {
                Write-Error "Error: Inkscape is required for SVG conversion but was not found in your system's PATH. Please install Inkscape or add it to your PATH."
                Write-Host "DEBUG: Inkscape not found. Returning."
                return
            }
            Write-Verbose "Inkscape command found at: $($inkscapeCmd.Source)"

            # Create a temporary PNG file path
            $tmpPng = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ([System.Guid]::NewGuid().ToString() + ".png"))
            Write-Verbose "Temporary PNG file will be created at: '$tmpPng'."

            # Execute Inkscape for SVG to PNG conversion
            $inkscapeArgs = @(
                "$File",
                "--export-type=png",
                "--export-filename=$tmpPng",
                "--export-width=256", # Corrected option for modern Inkscape
                "--export-height=256" # Corrected option for modern Inkscape
            )
            Write-Verbose "Running Inkscape command: '$($inkscapeCmd.Source) $($inkscapeArgs -join ' ')'"
            $inkscapeResult = & $inkscapeCmd.Source $inkscapeArgs 2>&1
            Write-Verbose "Inkscape command executed. Checking for temporary PNG..."

            # --- CRITICAL DEBUGGING POINT: Check temporary PNG existence and size immediately after Inkscape ---
            if (-not (Test-Path $tmpPng -PathType Leaf)) {
                # Changed to Write-Host for guaranteed immediate visibility
                Write-Host "CRITICAL ERROR: SVG to PNG conversion failed. Temporary PNG file '$tmpPng' was NOT created by Inkscape." -ForegroundColor Red
                Write-Host "Inkscape output (if any): $inkscapeResult" -ForegroundColor Yellow
                Write-Host "DEBUG: SVG to PNG conversion failed: Temporary PNG not found. Returning."
                return # Exit here if file wasn't created
            }

            $tmpPngInfo = Get-Item $tmpPng
            if ($tmpPngInfo.Length -eq 0) {
                # Changed to Write-Host for guaranteed immediate visibility
                Write-Host "CRITICAL ERROR: Temporary PNG file '$tmpPng' was created but is empty (0 bytes). Inkscape may have failed silently or encountered an issue." -ForegroundColor Red
                Write-Host "Inkscape output (if any): $inkscapeResult" -ForegroundColor Yellow
                Write-Host "DEBUG: Temporary PNG is empty. Returning."
                return # Exit here if file is empty
            }
            # --- END CRITICAL DEBUGGING POINT ---

            Write-Verbose "SVG successfully converted to temporary PNG: '$tmpPng' (Size: $($tmpPngInfo.Length) bytes)."
            $pngPath = $tmpPng
            $tmpPngCreated = $true
        }
        else {
            Write-Verbose "Input file is not an SVG. Using original file directly."
            $pngPath = $File
        }

        # --- CRITICAL DEBUGGING POINT: Loading System.Drawing ---
        Write-Host "DEBUG: Attempting to load System.Drawing assembly."
        try {
            Add-Type -AssemblyName System.Drawing -ErrorAction Stop
            Write-Host "DEBUG: System.Drawing assembly loaded successfully."
        }
        catch {
            Write-Error "CRITICAL ERROR: Failed to load System.Drawing assembly. This is required for image processing."
            Write-Error "Error Message: $($_.Exception.Message)"
            Write-Error "Error Line: $($_.InvocationInfo.ScriptLineNumber)"
            if ($_.Exception.InnerException) {
                Write-Error "Inner Exception: $($_.Exception.InnerException.Message)"
            }
            Write-Host "DEBUG: System.Drawing load failed. Exiting."
            return # Exit immediately if this critical assembly can't be loaded
        }
        # --- END CRITICAL DEBUGGING POINT ---

        # --- DEBUGGING POINT: Before Image.FromFile ---
        Write-Host "DEBUG: About to call System.Drawing.Image.FromFile('$pngPath')."
        # --- END DEBUGGING POINT ---

        # Load the image using System.Drawing
        Write-Verbose "Loading image from '$pngPath' using System.Drawing.Image.FromFile."
        $img = [System.Drawing.Image]::FromFile($pngPath)
        Write-Verbose "Image loaded successfully. Original size: $($img.Width)x$($img.Height)."

        # Define the desired icon size (standard for Windows icons often includes 256x256)
        $iconSize = [System.Drawing.Size]::new(256, 256)
        Write-Verbose "Resizing image to $($iconSize.Width)x$($iconSize.Height) for icon creation."

        # Create a new Bitmap object with the desired size and draw the image onto it
        $bmp = New-Object System.Drawing.Bitmap $iconSize.Width, $iconSize.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($img, 0, 0, $iconSize.Width, $iconSize.Height)
        $graphics.Dispose() # Dispose of the Graphics object immediately
        Write-Verbose "Bitmap created and image drawn."

        # Create the ICO file using System.Drawing.Icon
        $icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
        Write-Verbose "System.Drawing.Icon object created from bitmap."

        # Open a FileStream to write the ICO data
        $fs = [System.IO.FileStream]::new($OutputFile, [System.IO.FileMode]::Create)
        Write-Verbose "FileStream opened for writing to '$OutputFile'."

        # Save the icon to the file stream
        $icon.Save($fs)
        Write-Verbose "Icon saved to file stream."

        # Close the FileStream
        $fs.Close()
        Write-Verbose "FileStream closed."

        # Verify the output file was created and has content
        if (Test-Path $OutputFile -PathType Leaf) {
            $fileInfo = Get-Item $OutputFile
            if ($fileInfo.Length -gt 0) {
                Write-Host "Success: Icon '$OutputFile' created successfully with size $($fileInfo.Length) bytes."
            }
            else {
                Write-Error "Error: Icon '$OutputFile' was created but appears to be empty (0 bytes)."
            }
        }
        else {
            Write-Error "Error: Failed to create icon file at '$OutputFile'. File does not exist after save operation."
        }
    }
    catch {
        # Catch any errors that occur during the process
        Write-Error "An unexpected error occurred during icon conversion:"
        Write-Error "Error Message: $($_.Exception.Message)"
        Write-Error "Error Line: $($_.InvocationInfo.ScriptLineNumber)"
        if ($_.Exception.InnerException) {
            Write-Error "Inner Exception: $($_.Exception.InnerException.Message)"
        }
        Write-Host "DEBUG: Error caught in main catch block."
    }
    finally {
        # Ensure all disposable objects are cleaned up
        Write-Verbose "Cleaning up resources."
        if ($fs) { $fs.Dispose() }
        if ($icon) { $icon.Dispose() }
        if ($bmp) { $bmp.Dispose() }
        if ($img) { $img.Dispose() }

        # Remove temporary PNG file if it was created
        if ($tmpPngCreated -and (Test-Path $pngPath -PathType Leaf)) {
            Write-Verbose "Removing temporary PNG file: '$pngPath'."
            try {
                Remove-Item $pngPath -Force -ErrorAction Stop
                Write-Verbose "Temporary PNG removed."
            }
            catch {
                Write-Warning "Warning: Failed to remove temporary PNG file '$pngPath'. $($_.Exception.Message)"
            }
        }
        Write-Verbose "Conversion process finished."
        Write-Host "DEBUG: Function finished (finally block)."
    }
}
