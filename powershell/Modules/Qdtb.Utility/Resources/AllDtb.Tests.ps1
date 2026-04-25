
Describe 'Developer Tools Tests' {
    BeforeAll {
        Get-ChildItem -Path ".\Modules\Dios Te Bendiga\Other\Developer.ps1" | ForEach-Object { . $_.FullName }
        # $appmodulepath = Resolve-Path $PSScriptRoot/../DiosTeB.psd1
        # Import-Module "$appmodulepath"
    }
    It 'Should start projects' {
        Start-MyProject
    }
}


Describe 'Filesystem Tests' {
    BeforeAll {
        $appmodulepath = Resolve-Path $PSScriptRoot/../DiosTeB.psd1
        Import-Module "$appmodulepath"
    }
    It 'Should download a file successfully' {
        $fileName = "example.txt"
        $url = "https://example.com/file.txt"
        $outputPath = "C:\Users\nateb\Desktop\example.txt"
        DownloadFile -fileName $fileName -url $url -outputPath $outputPath
        Test-Path $outputPath | Should -Be $true
    }
}

Describe 'Media Tests' {
    BeforeAll {
        $appmodulepath = Resolve-Path $PSScriptRoot/../DiosTeB.psd1
        Import-Module "$appmodulepath"
    }
    It 'Should convert WebP to PNG successfully' {
        $inputDir = "C:\Users\nateb\Desktop"
        $outputDir = "C:\Users\nateb\Desktop"
        Convert-WebpToPng -inputDir $inputDir -outputDir $outputDir
        $outputFile = Join-Path -Path $outputDir -ChildPath "example.png"
        Test-Path $outputFile | Should -Be $true
    }
}

Describe 'Shell Tests' {
    BeforeAll {
        $appmodulepath = Resolve-Path $PSScriptRoot/../DiosTeB.psd1
        Import-Module "$appmodulepath"
    }
    It 'Should write rainbow prompt successfully' {
        $platform = "Unix"
        Write-RainbowPrompt -platform $platform
        $output = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $output.Character | Should -Be "❯"
    }
}
