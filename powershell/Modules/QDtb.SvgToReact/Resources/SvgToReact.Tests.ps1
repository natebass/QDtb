<#
    Pester tests for QDtb.SvgToReact.

    Hermetic: the suite runs inside a temp directory created by New-PesterSandbox and the
    module is loaded from $PSScriptRoot, not from the current directory. That matters here
    more than in most suites, because Write-ModuleLog writes 'script.log' and
    New-IconDirectory creates 'icon/' relative to wherever the process happens to be - so
    these tests used to leave both behind in whatever folder Invoke-Pester was run from.

    Invoke-Pester -Path ./Resources
#>
BeforeAll {
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path (Split-Path -Parent (Split-Path -Parent $script:ModuleRoot)) 'Tests/TestSandbox.psm1') -Force
    Import-Module (Join-Path $script:ModuleRoot 'QDtb.SvgToReact.psd1') -Force
    $script:Sandbox = New-PesterSandbox -Name 'svgtoreact'
}

AfterAll {
    Remove-Module QDtb.SvgToReact -Force -ErrorAction SilentlyContinue
    Remove-PesterSandbox -Sandbox $script:Sandbox
    Remove-Module TestSandbox -Force -ErrorAction SilentlyContinue
}

Describe 'Convert-SvgAttributesReact' {
    It 'renames the hyphenated SVG attributes React does not accept' {
        $converted = Convert-SvgAttributesReact -svgContent '<svg stroke-linecap="round" stroke-linejoin="round" stroke-width="2" fill-rule="evenodd" clip-rule="evenodd" clip-path="url(#clip)"></svg>'
        $converted | Should -Match 'strokeLinecap="round"'
        $converted | Should -Match 'strokeLinejoin="round"'
        $converted | Should -Match 'strokeWidth="2"'
        $converted | Should -Match 'fillRule="evenodd"'
        $converted | Should -Match 'clipRule="evenodd"'
        $converted | Should -Match 'clipPath="url\(#clip\)"'
    }

    It 'leaves content with nothing to rename alone' {
        $svg = '<svg viewBox="0 0 24 24"><path d="M0 0h24v24H0z"/></svg>'
        Convert-SvgAttributesReact -svgContent $svg | Should -Be $svg
    }
}

Describe 'Convert-ComponentContent' {
    BeforeAll {
        $script:Simple = '<svg width="24" height="24"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>'
    }

    It 'declares a component and an interface under the given name' {
        $content = Convert-ComponentContent -svgContent $script:Simple -componentName 'TestComponent'
        $content | Should -Match 'export const TestComponent'
        $content | Should -Match 'interface TestComponentProps'
    }

    It 'keeps the inner markup' {
        Convert-ComponentContent -svgContent $script:Simple -componentName 'TestComponent' |
            Should -Match '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>'
    }

    It 'lifts width and height out of the attributes and into props' {
        $content = Convert-ComponentContent -svgContent $script:Simple -componentName 'TestComponent'
        $content | Should -Match 'width = 24'
        $content | Should -Match 'height = 24'
        # The literal attributes must not survive alongside the props, or React sees both.
        $content | Should -Not -Match 'width="24"'
        $content | Should -Not -Match 'height="24"'
    }

    It 'falls back to 24 when the source gives no size' {
        $content = Convert-ComponentContent -svgContent '<svg viewBox="0 0 32 32"><path d="M0 0"/></svg>' -componentName 'NoSize'
        $content | Should -Match 'width = 24'
        $content | Should -Match 'height = 24'
        $content | Should -Match 'viewBox="0 0 32 32"'
    }

    It 'rejects content that is not an SVG' {
        { Convert-ComponentContent -svgContent 'not an svg at all' -componentName 'Bad' } |
            Should -Throw -ExpectedMessage '*Invalid SVG format*'
    }
}

Describe 'Convert-ToPascalCase' {
    It 'converts <Filename> to <Expected>' -ForEach @(
        @{ Filename = 'example-file.svg'; Expected = 'ExampleFile' }
        @{ Filename = 'exampleFile.svg'; Expected = 'Examplefile' }
        @{ Filename = 'example_file.svg'; Expected = 'ExampleFile' }
        @{ Filename = 'example file.svg'; Expected = 'ExampleFile' }
        @{ Filename = 'icon.svg'; Expected = 'Icon' }
    ) {
        InModuleScope QDtb.SvgToReact -Parameters @{ f = $Filename } {
            param($f) Convert-ToPascalCase -filename $f
        } | Should -Be $Expected
    }
}

Describe 'Write-ModuleLog' {
    It 'appends a timestamped line to the log in the working directory' {
        InModuleScope QDtb.SvgToReact {
            Remove-Item -LiteralPath 'script.log' -ErrorAction SilentlyContinue
            Write-ModuleLog -Level 'INFO' -Message 'Test message' | Out-Null
        }
        # The sandbox is the working directory, so this is where the module writes.
        $log = Join-Path $script:Sandbox.Path 'script.log'
        Test-Path -LiteralPath $log | Should -BeTrue
        (Get-Content -LiteralPath $log -Raw) | Should -Match 'INFO - Test message'
    }
}

Describe 'New-IconDirectory' {
    It 'creates the directory and returns its name' {
        $result = InModuleScope QDtb.SvgToReact {
            Remove-Item -LiteralPath 'icon' -Recurse -Force -ErrorAction SilentlyContinue
            New-IconDirectory
        }
        $result | Should -Be 'icon'
        Test-Path -LiteralPath (Join-Path $script:Sandbox.Path 'icon') | Should -BeTrue
    }

    It 'creates nothing under -WhatIf' {
        InModuleScope QDtb.SvgToReact {
            Remove-Item -LiteralPath 'icon' -Recurse -Force -ErrorAction SilentlyContinue
            New-IconDirectory -WhatIf | Out-Null
        }
        Test-Path -LiteralPath (Join-Path $script:Sandbox.Path 'icon') | Should -BeFalse
    }
}

Describe 'Convert-FolderSvgToReact' {
    BeforeEach {
        $script:WorkDir = Join-Path $script:Sandbox.Path "folder-$([guid]::NewGuid().ToString('N').Substring(0,6))"
        New-Item -ItemType Directory -Path $script:WorkDir -Force | Out-Null
    }

    It 'writes one component per SVG in the folder' {
        Set-Content -LiteralPath (Join-Path $script:WorkDir 'home-icon.svg') -Value '<svg width="16" height="16"><path d="M1 1"/></svg>'
        Set-Content -LiteralPath (Join-Path $script:WorkDir 'user.svg') -Value '<svg stroke-width="2"><circle cx="1" cy="1" r="1"/></svg>'

        Push-Location -LiteralPath $script:WorkDir
        try { Convert-FolderSvgToReact -path $script:WorkDir -InformationAction SilentlyContinue }
        finally { Pop-Location }

        $icons = Join-Path $script:WorkDir 'icon'
        Test-Path -LiteralPath (Join-Path $icons 'HomeIcon.tsx') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $icons 'User.tsx') | Should -BeTrue
        # The attribute conversion has to happen before the component is written out.
        (Get-Content -LiteralPath (Join-Path $icons 'User.tsx') -Raw) | Should -Match 'strokeWidth="2"'
    }

    It 'writes nothing when the folder holds no SVGs' {
        Push-Location -LiteralPath $script:WorkDir
        try { Convert-FolderSvgToReact -path $script:WorkDir -InformationAction SilentlyContinue }
        finally { Pop-Location }
        Test-Path -LiteralPath (Join-Path $script:WorkDir 'icon') | Should -BeFalse
    }
}

