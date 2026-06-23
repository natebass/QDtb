
<#
.SYNOPSIS
    Retrieves and downloads episodes from an RSS XML file.

.EXAMPLE
    $SourceFile = "C:\Users\nateb\Source\Temp\a.xml"
    $TargetFolder = "C:\Users\nateb\Source\Temp"
    $EpisodeNumber = 2

    Save-RSSEpisode -RSSFile $SourceFile -TargetFolder $TargetFolder -EpisodeNumber $EpisodeNumber

    Description
    -----------
    This command parses the local 'a.xml' file and downloads the first 2 podcast episodes found inside it to the target directory.

.PARAMETER RSSFile
    The path to the RSS XML file. Defaults to "C:\Users\nateb\Source\Temp\a.xml".

.PARAMETER TargetFolder
    The folder where the episodes will be downloaded. Defaults to "C:\Users\nateb\Source\Temp".

.PARAMETER EpisodeNumber
    The number of episodes to retrieve from the RSS feed. Defaults to 2.
#>
function Save-RSSEpisode {
    [CmdletBinding()]
    param (
        [string]$RSSFile,
        [string]$TargetFolder,
        [Int32]$EpisodeNumber
    )
    [xml]$rss = Get-Content $RSSFile
    if (!(Test-Path -Path $targetFolder)) {
        New-Item -ItemType Directory -Path $targetFolder | Out-Null
    }
    $episodes = $rss.rss.channel.item | Select-Object -First $EpisodeNumber
    foreach ($episode in $episodes) {
        Save-Mp3File -episode $episode -targetFolder $TargetFolder -outputPath $O
    }
}
