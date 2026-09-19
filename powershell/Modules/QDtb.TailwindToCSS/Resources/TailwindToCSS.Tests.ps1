# Pester Test File for the new Convert-TailwindToCSS engine
# Requires Pester 5+

BeforeAll {
    # Determine the module root and import all public and private functions
    $moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent
    Get-ChildItem -Path (Join-Path $moduleRoot 'Functions\Private') -Filter '*.ps1' -Recurse | ForEach-Object { . $_.FullName }
    Get-ChildItem -Path (Join-Path $moduleRoot 'Functions\Public') -Filter '*.ps1' -Recurse | ForEach-Object { . $_.FullName }
}

Describe 'Comprehensive Tailwind to CSS Conversion' {

    Context 'Core Functionality' {
        It 'should convert a simple utility class' {
            $css = Convert-TailwindToCSS -TailwindContent 'text-center' -ClassName 'my-div'
            $css | Should -Be ".my-div {`n    text-align: center;`n}"
        }

        It 'should convert multiple static utility classes' {
            $css = Convert-TailwindToCSS -TailwindContent 'flex items-center' -ClassName 'container'
            $css | Should -Contain ".container {`n    display: flex;`n}"
            $css | Should -Contain ".container {`n    align-items: center;`n}"
        }
    }

    Context 'Programmatic Spacing and Sizing' {
        It 'should handle padding utilities (p, pt, px)' {
            $css = Convert-TailwindToCSS -TailwindContent 'p-4 pt-2 px-6' -ClassName 'box'
            $css | Should -Contain ".box {`n    padding: 1rem;`n}"
            $css | Should -Contain ".box {`n    padding-top: 0.5rem;`n}"
            $css | Should -Contain ".box {`n    padding-left: 1.5rem;`n    padding-right: 1.5rem;`n}"
        }

        It 'should handle negative margin utilities (-mt-4)' {
            $css = Convert-TailwindToCSS -TailwindContent '-mt-4' -ClassName 'header'
            $css | Should -Be ".header {`n    margin-top: -1rem;`n}"
        }

        It 'should handle arbitrary width (w-[300px])' {
            $css = Convert-TailwindToCSS -TailwindContent 'w-[300px]' -ClassName 'panel'
            $css | Should -Be ".panel {`n    width: 300px;`n}"
        }

        It 'should handle arbitrary height with css variable' {
            $css = Convert-TailwindToCSS -TailwindContent 'h-[var(--header-height)]' -ClassName 'content'
            $css | Should -Be ".content {`n    height: var(--header-height);`n}"
        }
    }

    Context 'Color Utilities' {
        It 'should handle background colors (bg-blue-500)' {
            $css = Convert-TailwindToCSS -TailwindContent 'bg-blue-500' -ClassName 'button'
            $css | Should -Be ".button {`n    background-color: #3b82f6;`n}"
        }

        It 'should handle text colors (text-red-700)' {
            $css = Convert-TailwindToCSS -TailwindContent 'text-red-700' -ClassName 'error'
            $css | Should -Be ".error {`n    color: #b91c1c;`n}"
        }

        It 'should handle border colors with default class name' {
            $css = Convert-TailwindToCSS -TailwindContent 'border-green-500'
            $css | Should -Be ".a {`n    border-color: #22c55e;`n}"
        }
    }

    Context 'Variants (Responsive, States, Dark Mode)' {
        It 'should handle responsive variants (md:text-lg)' {
            $css = Convert-TailwindToCSS -TailwindContent 'md:text-lg' -ClassName 'title'
            $expected = "@media (min-width: 768px) {`n    .title {`n        font-size: 1.125rem;`n        line-height: 1.75rem;`n    }`n}"
            $css.Replace("`r`n", "`n") | Should -Be $expected.Replace("`r`n", "`n")
        }

        It 'should handle state variants (hover:underline)' {
            $css = Convert-TailwindToCSS -TailwindContent 'hover:underline' -ClassName 'link'
            $css | Should -Be ".link:hover {`n    text-decoration-line: underline;`n}"
        }

        It 'should handle dark mode variant (dark:bg-gray-900)' {
            $css = Convert-TailwindToCSS -TailwindContent 'dark:bg-gray-900' -ClassName 'card'
            $css | Should -Be ".dark .card {`n    background-color: #111827;`n}"
        }

        It 'should handle combined variants (dark:md:hover:bg-gray-800)' {
            $css = Convert-TailwindToCSS -TailwindContent 'dark:md:hover:bg-gray-800' -ClassName 'button'
            $expected = "@media (min-width: 768px) {`n    .dark .button:hover {`n        background-color: #1f2937;`n    }`n}"
            $css.Replace("`r`n", "`n") | Should -Be $expected.Replace("`r`n", "`n")
        }

        It 'should handle multiple complex classes at once' {
            $tailwind = 'p-4 bg-white dark:bg-slate-800 md:p-8'
            $css = Convert-TailwindToCSS -TailwindContent $tailwind -ClassName 'card'
            $css | Should -Contain ".card {`n    padding: 1rem;`n}"
            $css | Should -Contain ".card {`n    background-color: #fff;`n}"
            $css | Should -Contain ".dark .card {`n    background-color: #1e293b;`n}"
            $css | Should -Contain "@media (min-width: 768px)"
            $css | Should -Contain ".card {`n        padding: 2rem;`n    }"
        }
    }

    Context 'Edge Cases' {
        It 'should ignore unknown utility classes and write a warning' {
            { $css = Convert-TailwindToCSS -TailwindContent 'this-is-not-real' } | Should -WriteWarning -Like '*not recognized*'
            $css | Should -BeNullOrEmpty()
        }

        It 'should process valid classes even when mixed with invalid ones' {
            { $css = Convert-TailwindToCSS -TailwindContent 'pt-4 this-is-fake mt-2' } | Should -WriteWarning
            $css | Should -Contain 'padding-top: 1rem;'
            $css | Should -Contain 'margin-top: 0.5rem;'
            $css | Should -Not -Contain 'this-is-fake'
        }

        It 'should handle empty or whitespace-only input' {
            $css = Convert-TailwindToCSS -TailwindContent '   '
            $css | Should -BeNullOrEmpty()
        }
    }
}

