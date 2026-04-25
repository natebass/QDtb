
function Save-RSSEpisode {
    # aaaa
    <#
.SYNOPSIS
    Retrieves and downloads episodes from an RSS XML file.

.SYNOPSIS
    The Save-RSSEpisode function loads an RSS XML file, retrieves a specified number of episodes, 
    and downloads the associated audio files into a target folder. If the target folder does 
    not exist, it will create it.

.PARAMETER RSSFile
    The path to the RSS XML file. Defaults to "C:\Users\nateb\Source\Temp\a.xml".

.PARAMETER TargetFolder
    The folder where the episodes will be downloaded. Defaults to "C:\Users\nateb\Source\Temp".

.PARAMETER EpisodeNumber
    The number of episodes to retrieve from the RSS feed. Defaults to 2.
#>
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
