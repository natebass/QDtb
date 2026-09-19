<#
.SYNOPSIS
Converts a string of Tailwind CSS utility classes into standard CSS rules.

.DESCRIPTION
This advanced function takes a string of space-separated Tailwind CSS class names and converts them into corresponding CSS rules.
It leverages a powerful internal engine to handle the full spectrum of Tailwind CSS features, including:
- Responsive variants (sm:, md:, lg:, etc.)
- State variants (hover:, focus:, active:, etc.)
- Dark mode (dark:)
- Programmatic scales for spacing, sizing, and typography.
- Arbitrary values (e.g., w-[300px], text-[1.1rem]).

The function allows you to specify a class name for the generated CSS rules. If no class name is provided, it defaults to 'a'.

.PARAMETER TailwindContent
A string containing one or more space-separated Tailwind CSS class names.

.PARAMETER ClassName
(Optional) The name of the CSS class to be created. If not specified, the default value is 'a'.

.EXAMPLE
PS C:\> Convert-TailwindToCSS -TailwindContent 'md:hover:text-red-500 pt-4' -ClassName 'my-button'

@media (min-width: 768px) {
    .my-button:hover {
        color: #ef4444;
    }
}
.my-button {
    padding-top: 1rem;
}

This example converts two Tailwind classes, including a responsive and stateful variant, into two separate CSS rules.

.OUTPUTS
System.String
A formatted string containing all the generated CSS rules.
#>
function Convert-TailwindToCSS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$TailwindContent,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$ClassName = 'a'
    )

    begin {
        # Find and source helper functions from the module's private directory.
        #        $privateFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\\Private'
        #        Get-ChildItem -Path $privateFunctionsPath -Filter '*.ps1' | ForEach-Object {
        #            . $_.FullName
        #        }

        # Load the comprehensive Tailwind data map.
        $tailwindMap = Get-TailwindMap
    }

    process {
        $allCssRules = [System.Collections.Generic.List[string]]::new()
        $classes = $TailwindContent -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        foreach ($class in $classes) {
            try {
                $cssRule = Convert-TailwindClassToCss -Class $class -ClassName $ClassName -TailwindMap $tailwindMap
                if (-not [string]::IsNullOrWhiteSpace($cssRule)) {
                    $allCssRules.Add($cssRule)
                }
            }
            catch {
                $errorMessage = if ($_.Exception.Message) { $_.Exception.Message } else { $_ }
                Write-Warning "Failed to process class '$class': $errorMessage"
            }
        }

        if ($allCssRules.Count -gt 0) {
            # Join all generated CSS rules into a single string.
            Write-Output ($allCssRules -join ([Environment]::NewLine * 2))
        }
    }
}
