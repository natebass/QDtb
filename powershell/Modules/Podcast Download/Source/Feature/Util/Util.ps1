
function Save-PodcastEpisode {
    [CmdletBinding()]
    param (
        [string]$SourceFile = "C:\Users\nateb\Source\Temp\a.xml",
        [string]$TargetFolder = "C:\Users\nateb\Source\Temp",
        [Int32]$EpisodeNumber = 2
    )
    Save-RSSEpisode -RSSFile $SourceFile -TargetFolder $TargetFolder -EpisodeNumber $EpisodeNumber
}
