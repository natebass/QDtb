
BeforeAll {
    Get-ChildItem -Path ".\Modules\SVG to React\Functions\Private\*.ps1" | ForEach-Object { . $_.FullName }
    Get-ChildItem -Path ".\Modules\SVG to React\Functions\Public\*.ps1" | ForEach-Object { . $_.FullName }
}
Describe 'General SVG to React tests' {
    It 'Convert-ComponentContent should generate valid React component content' {
        $svgContent = '<svg width="24" height="24"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>'
        $componentName = "TestComponent"
        $componentContent = Convert-ComponentContent -svgContent $svgContent -componentName $componentName
        $componentContent | Should -Contain "export const TestComponent"
    }
    It 'CreateIndexFile should create an index file with component exports' {
        $iconDir = "icon"
        $componentNames = [System.Collections.Generic.HashSet[string]]::new()
        $componentNames.Add("TestComponent")
        CreateIndexFile -iconDir $iconDir -componentNames $componentNames
        $indexPath = Join-Path -Path $iconDir -ChildPath "index.ts"
        $indexContent = Get-Content -Path $indexPath
        $indexContent | Should -Contain "export * from './TestComponent';"
    }
    It 'Convert-SvgAttributesReact should convert SVG attributes to React attributes' {
        $svgContent = '<svg stroke-linecap="round" stroke-linejoin="round" stroke-width="2" fill-rule="evenodd" clip-rule="evenodd" clip-path="url(#clip)"></svg>'
        $convertedContent = Convert-SvgAttributesReact -svgContent $svgContent
        $convertedContent | Should -Match 'strokeLinecap="round"'
        $convertedContent | Should -Match 'strokeLinejoin="round"'
        $convertedContent | Should -Match 'strokeWidth="2"'
        $convertedContent | Should -Match 'fillRule="evenodd"'
        $convertedContent | Should -Match 'clipRule="evenodd"'
        $convertedContent | Should -Match 'clipPath="url\(#clip\)"'
    }
    It 'Write-Log should log messages correctly' {
        $logFile = "script.log"
        Remove-Item -Path $logFile -ErrorAction Ignore
        Write-Log -level "INFO" -message "Test message"
        $logContent = Get-Content -Path $logFile
        $logContent | Should -Match "INFO - Test message"
    }
    It 'SetupIconDirectory should create icon directory if not exists' {
        $iconDir = "icon"
        Remove-Item -Path $iconDir -Recurse -Force -ErrorAction Ignore
        SetupIconDirectory | Should -Be $iconDir
        Test-Path -Path $iconDir | Should -Be $true
    }
    It 'To-PascalCase should convert filenames to PascalCase' {
        Convert-ToPascalCase -filename "example-file.svg" | Should -Be "ExampleFile"
        Convert-ToPascalCase -filename "exampleFile.svg" | Should -Be "ExampleFile"
        Convert-ToPascalCase -filename "example_file.svg" | Should -Be "ExampleFile"
        Convert-ToPascalCase -filename "example file.svg" | Should -Be "ExampleFile"
    }
}
