<#
    Pester tests for PodcastDownload.

    Hermetic: the RSS feed is a fixture written into a temp sandbox, and Invoke-WebRequest
    is mocked inside the module, so no episode is ever fetched and nothing is written
    outside the sandbox. The point of the download tests is the parsing and the naming,
    which is where the bugs live; actually pulling an mp3 over the network would test the
    internet rather than this module.

    Invoke-Pester -Path ./Test
#>
BeforeAll {
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path (Split-Path -Parent (Split-Path -Parent $script:ModuleRoot)) 'Tests/TestSandbox.psm1') -Force
    Import-Module (Join-Path $script:ModuleRoot 'PodcastDownload.psd1') -Force
    $script:Sandbox = New-PesterSandbox -Name 'podcast'

    $script:FeedPath = Join-Path $script:Sandbox.Path 'feed.xml'
    Set-Content -LiteralPath $script:FeedPath -Encoding utf8 -Value @'
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>First: Episode / One</title>
      <enclosure url="https://example.invalid/one.mp3" type="audio/mpeg" />
    </item>
    <item>
      <title>Second Episode</title>
      <enclosure url="https://example.invalid/two.mp3" type="audio/mpeg" />
    </item>
    <item>
      <title>Third Episode</title>
      <enclosure url="https://example.invalid/three.mp3" type="audio/mpeg" />
    </item>
  </channel>
</rss>
'@
}

AfterAll {
    Remove-Module PodcastDownload -Force -ErrorAction SilentlyContinue
    Remove-PesterSandbox -Sandbox $script:Sandbox
    Remove-Module TestSandbox -Force -ErrorAction SilentlyContinue
}

Describe 'Save-RSSEpisode' {
    BeforeEach {
        # Nothing leaves the machine: the download itself is the only real side effect and
        # it is replaced here.
        Mock -ModuleName PodcastDownload Invoke-WebRequest { }
        $script:Target = Join-Path $script:Sandbox.Path "out-$([guid]::NewGuid().ToString('N').Substring(0,6))"
    }

    It 'downloads as many episodes as it was asked for' {
        Save-RSSEpisode -RSSFile $script:FeedPath -TargetFolder $script:Target -EpisodeNumber 2
        Should -Invoke -ModuleName PodcastDownload Invoke-WebRequest -Times 2 -Exactly
    }

    It 'takes the episodes from the top of the feed' {
        Save-RSSEpisode -RSSFile $script:FeedPath -TargetFolder $script:Target -EpisodeNumber 1
        Should -Invoke -ModuleName PodcastDownload Invoke-WebRequest -Times 1 -Exactly `
            -ParameterFilter { $Uri -eq 'https://example.invalid/one.mp3' }
    }

    It 'creates the target folder when it does not exist' {
        Test-Path -LiteralPath $script:Target | Should -BeFalse
        Save-RSSEpisode -RSSFile $script:FeedPath -TargetFolder $script:Target -EpisodeNumber 1
        Test-Path -LiteralPath $script:Target | Should -BeTrue
    }

    It 'strips the characters a filename cannot hold from the episode title' {
        Save-RSSEpisode -RSSFile $script:FeedPath -TargetFolder $script:Target -EpisodeNumber 1
        Should -Invoke -ModuleName PodcastDownload Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
            # 'First: Episode / One' must not keep its colon, slash or spaces.
            $OutFile -like '*First*Episode*One.mp3' -and $OutFile -notmatch '[:/ ]One'
        }
    }

    It 'asks for one file per episode, into the target folder' {
        Save-RSSEpisode -RSSFile $script:FeedPath -TargetFolder $script:Target -EpisodeNumber 3
        Should -Invoke -ModuleName PodcastDownload Invoke-WebRequest -Times 3 -Exactly `
            -ParameterFilter { $OutFile.StartsWith($script:Target) }
    }
}

Describe 'Module surface' {
    It 'exports every function the manifest promises' {
        $declared = (Import-PowerShellDataFile (Join-Path $script:ModuleRoot 'PodcastDownload.psd1')).FunctionsToExport
        $actual = (Get-Command -Module PodcastDownload).Name
        $declared | Where-Object { $_ -notin $actual } | Should -BeNullOrEmpty
    }

    It 'loads the private helpers its public functions call' {
        # Save-RSSEpisode is built out of Save-Mp3File; the loader used to skip Private
        # entirely, so the module imported cleanly and then failed on first use.
        InModuleScope PodcastDownload { Get-Command Save-Mp3File -ErrorAction SilentlyContinue } |
            Should -Not -BeNullOrEmpty
    }
}

