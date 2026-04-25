
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
    Write-Output "Conversion complete!"
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
<#
.SYNOPSIS
    Downloads a podcast episode and saves it to a specified folder.

.SYNOPSIS
    The Save-Mp3File function takes a podcast episode object and a target folder as input. It sanitizes the episode title to create a valid filename, constructs the output path, and downloads the audio file to the specified location.

.PARAMETER episode
    The podcast episode object that contains details such as title and enclosure URL.

.PARAMETER targetFolder
    The target folder where the podcast episode should be saved.

.EXAMPLE
    Save-Mp3File -episode $episode -targetFolder "C:\Podcasts"
    Downloads the specified podcast episode and saves it in the C:\Podcasts folder.

.NOTES
    This script requires a function named 'DownloadFile' to handle the actual download of the podcast file.
    The podcast episode object that contains details such as title and enclosure URL
    The target folder where the podcast episode should be saved
    Remove invalid filename characters from the episode title
    Invalid characters for filenames include: / \ : * ? " < > | 
    The regex pattern '[\/:*?"<>| ]' is used to replace these characters with an empty string
    Get the URL for the episode's audio file
    The URL for the audio file is retrieved from the enclosure property of the episode object
    Construct the full output path for the downloaded file
    Join-Path is used to combine the target folder path and the sanitized episode title to create the output path
    The file will be saved with an .mp3 extension
    Download the audio file to the specified folder
    DownloadFile is a function that takes in the fileName, url, targetFolder, and outputPath to download the file
#>
function Save-Mp3File {
    [CmdletBinding()]
    param (
        $episode,
        $targetFolder
    )
    $title = $episode.title -replace '[\/:*?"<>| ]', ""
    $url = $episode.enclosure.url
    $outputPath = Join-Path -Path $targetFolder -ChildPath "$title.mp3"
    DownloadFile -fileName $title -url $url -targetFolder $targetFolder -outputPath $outputPath
}
function Convert-ToJpeg {
    # ConvertTo-Jpeg - Converts RAW (and other) image files to the widely-supported JPEG format
    # https://github.com/DavidAnson/ConvertTo-Jpeg

    Param (
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = "Array of image file names to convert to JPEG")]
        [Alias("FullName")]
        [String[]]
        $Files,

        [Parameter(
            HelpMessage = "Fix extension of JPEG files without the .jpg extension")]
        [Switch]
        [Alias("f")]
        $FixExtensionIfJpeg,

        [Parameter(
            HelpMessage = "Remove existing extension of non-JPEG files before adding .jpg")]
        [Switch]
        [Alias("r")]
        $RemoveOriginalExtension
    )

    Begin {
        # Technique for await-ing WinRT APIs: https://fleexlab.blogspot.com/2018/02/using-winrts-iasyncoperation-in.html
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $runtimeMethods = [System.WindowsRuntimeSystemExtensions].GetMethods()
        $asTaskGeneric = ($runtimeMethods | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
        Function AwaitOperation ($WinRtTask, $ResultType) {
            $asTaskSpecific = $asTaskGeneric.MakeGenericMethod($ResultType)
            $netTask = $asTaskSpecific.Invoke($null, @($WinRtTask))
            $netTask.Wait() | Out-Null
            $netTask.Result
        }
        $asTask = ($runtimeMethods | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' })[0]
        Function AwaitAction ($WinRtTask) {
            $netTask = $asTask.Invoke($null, @($WinRtTask))
            $netTask.Wait() | Out-Null
        }

        # Reference WinRT assemblies
        [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
        [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType = WindowsRuntime] | Out-Null
    }

    Process {
        # Summary of imaging APIs: https://docs.microsoft.com/en-us/windows/uwp/audio-video-camera/imaging
        foreach ($file in $Files) {
            Write-Host $file -NoNewline
            try {
                try {
                    # Get SoftwareBitmap from input file
                    $file = Resolve-Path -LiteralPath $file
                    $inputFile = AwaitOperation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($file)) ([Windows.Storage.StorageFile])
                    $inputFolder = AwaitOperation ($inputFile.GetParentAsync()) ([Windows.Storage.StorageFolder])
                    $inputStream = AwaitOperation ($inputFile.OpenReadAsync()) ([Windows.Storage.Streams.IRandomAccessStreamWithContentType])
                    $decoder = AwaitOperation ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($inputStream)) ([Windows.Graphics.Imaging.BitmapDecoder])
                }
                catch {
                    # Ignore non-image files
                    Write-Host " [Unsupported]"
                    continue
                }
                if ($decoder.DecoderInformation.CodecId -eq [Windows.Graphics.Imaging.BitmapDecoder]::JpegDecoderId) {
                    $extension = $inputFile.FileType
                    if ($FixExtensionIfJpeg -and ($extension -ne ".jpg") -and ($extension -ne ".jpeg")) {
                        # Rename JPEG-encoded files to have ".jpg" extension
                        $newName = $inputFile.Name -replace ($extension + "$"), ".jpg"
                        AwaitAction ($inputFile.RenameAsync($newName))
                        Write-Host " => $newName"
                    }
                    else {
                        # Skip JPEG-encoded files
                        Write-Host " [Already JPEG]"
                    }
                    continue
                }
                $bitmap = AwaitOperation ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
            
                # Determine output file name
                # Get name of original file, including extension
                $fileName = $inputFile.Name
                if ($RemoveOriginalExtension) {
                    # If removing original extension, get the original file name without the extension
                    $fileName = $inputFile.DisplayName 
                }
                # Add .jpg to the file name
                $outputFileName = $fileName + ".jpg"

                # Write SoftwareBitmap to output file
                $outputFile = AwaitOperation ($inputFolder.CreateFileAsync($outputFileName, [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
                $outputStream = AwaitOperation ($outputFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)) ([Windows.Storage.Streams.IRandomAccessStream])
                $encoder = AwaitOperation ([Windows.Graphics.Imaging.BitmapEncoder]::CreateAsync([Windows.Graphics.Imaging.BitmapEncoder]::JpegEncoderId, $outputStream)) ([Windows.Graphics.Imaging.BitmapEncoder])
                $encoder.SetSoftwareBitmap($bitmap)
                $encoder.IsThumbnailGenerated = $true

                # Do it
                AwaitAction ($encoder.FlushAsync())
                Write-Host " -> $outputFileName"
            }
            catch {
                # Report full details
                throw $_.Exception.ToString()
            }
            finally {
                # Clean-up
                if ($inputStream -ne $null) { [System.IDisposable]$inputStream.Dispose() }
                if ($outputStream -ne $null) { [System.IDisposable]$outputStream.Dispose() }
            }
        }
    }
}