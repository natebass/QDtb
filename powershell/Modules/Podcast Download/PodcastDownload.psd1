@{
    RootModule        = 'PodcastDownload.psm1'
    ModuleVersion     = '0.0.1'
    Author            = "Nate Bass"
    Description       = "Dowload podcast episodes via RSS."
    FunctionsToExport = @(
        'Save-RSSEpisode'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            DefaultDownloadPath    = 'C:\Podcasts'
            MaxConcurrentDownloads = 3
            Tags                   = @('Podcast', 'RSS', 'Download', 'Audio')
            LicenseUri             = 'https://github.com/natebass/podcast-download/blob/main/LICENSE'
            ProjectUri             = 'https://github.com/natebass/podcast-download'
            ReleaseNotes           = 'Fixed RSS parsing loop and optimized directory structure.'
        }
    }
}
