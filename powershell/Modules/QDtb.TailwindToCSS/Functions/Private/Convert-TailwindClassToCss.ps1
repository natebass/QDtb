function Convert-TailwindClassToCss {
    <#
    .SYNOPSIS
    Converts a single Tailwind CSS class string, including variants, into a full CSS rule.
    .DESCRIPTION
    This is the core conversion engine of the module. It takes a single class name (e.g., "dark:hover:md:bg-blue-500"),
    parses the variants (dark, hover, md) and the base utility (bg-blue-500), and constructs a complete CSS rule.
    It handles responsive breakpoints, pseudo-classes, dark mode, and programmatically generates CSS for utilities
    with values (e.g., spacing, colors, sizes). This is a private helper function.
    .PARAMETER Class
    The single Tailwind CSS class string to convert.
    .PARAMETER ClassName
    The CSS class name (e.g., "my-class") to apply the style to.
    .PARAMETER TailwindMap
    A hashtable containing the Tailwind CSS data mappings (colors, spacing, etc.), typically from Get-TailwindMap.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Class,

        [Parameter(Mandatory)]
        [string]$ClassName,

        [Parameter(Mandatory)]
        [hashtable]$TailwindMap
    )

    if (-not $TailwindMap) {
        throw "TailwindMap is null or empty"
    }

    @('spacing', 'colors', 'breakpoints', 'staticUtilities') | ForEach-Object {
        if (-not $TailwindMap.ContainsKey($_) -or $null -eq $TailwindMap[$_]) {
            throw "TailwindMap.$_ section is missing or null"
        }
    }

    if ($TailwindMap.spacing -isnot [hashtable]) {
        throw "TailwindMap.spacing must be a hashtable"
    }
    
    $parts = $Class -split ':'
    $utility = $parts[-1]  # Last part is always the utility
    $variants = if ($parts.Count -gt 1) { $parts[0..($parts.Count - 2)] } else { @() }

    $cssPropertyValue = ''
    $isNegative = $utility -and $utility.StartsWith('-')
    $utilityBase = if ($isNegative) { $utility.Substring(1) } else { $utility }
    $arbitraryRegex = '^(?<prop>[a-z-]+)-\[(?<val>.+)\]$'
    $arbitraryMatch = $utilityBase | Select-String -Pattern $arbitraryRegex

    if ($arbitraryMatch) {
        # Handle arbitrary values like `w-[300px]`
        $prop = $arbitraryMatch.Matches.Groups['prop'].Value
        $val = $arbitraryMatch.Matches.Groups['val'].Value.Replace('_', ' ')
        $cssVal = if ($isNegative) { "-$val" } else { $val }

        # This requires a map from class prefix to css property
        $propMap = @{
            'p' = 'padding'; 'pt' = 'padding-top'; 'pr' = 'padding-right'; 'pb' = 'padding-bottom'; 'pl' = 'padding-left'; 'px' = @('padding-left', 'padding-right'); 'py' = @('padding-top', 'padding-bottom');
            'm' = 'margin'; 'mt' = 'margin-top'; 'mr' = 'margin-right'; 'mb' = 'margin-bottom'; 'ml' = 'margin-left'; 'mx' = @('margin-left', 'margin-right'); 'my' = @('margin-top', 'margin-bottom');
            'w' = 'width'; 'h' = 'height'; 'min-w' = 'min-width'; 'min-h' = 'min-height'; 'max-w' = 'max-width'; 'max-h' = 'max-height';
            'basis' = 'flex-basis'; 'gap' = 'gap'; 'gap-x' = 'column-gap'; 'gap-y' = 'row-gap';
            'translate-x' = '--tw-translate-x'; 'translate-y' = '--tw-translate-y';
            'text' = 'font-size';
            # ... add more as needed
        }
        if ($propMap.ContainsKey($prop)) {
            $cssProps = [array]$propMap[$prop]
            foreach ($cssProp in $cssProps) {
                # NOTE: Changed
                # $cssPropertyValue += "$cssProp: $cssVal;"
                # $cssPropertyValue += "${cssProp}: ${cssVal};"
                $cssPropertyValue += "$( $cssProp ): $( $cssVal );"
            }
        }
    }
    else {
        # Handle keyword and scale-based values
        if ($TailwindMap.staticUtilities.ContainsKey($utility)) {
            $cssPropertyValue = $TailwindMap.staticUtilities[$utility]
        }
        else {
            # Pattern matching for dynamic utilities (colors, spacing, etc.)
            $parts = $utilityBase.Split('-')
            if ($parts.Count -lt 2) { return "" }            $prop = $parts[0]
            $value = $parts[1..($parts.Length - 1)] -join '-'
            Write-Debug "Extracted property: $prop, value: $value"

            switch -Regex ($prop) {
                '^(p|m)$' {
                    $cssProp = @{ 'p' = 'padding'; 'm' = 'margin' }[$prop]
                    if ($TailwindMap.spacing.ContainsKey($value)) {
                        $cssVal = if ($isNegative) { "-$($TailwindMap.spacing[$value])" } else { $TailwindMap.spacing[$value] }
                        $cssPropertyValue = "$cssProp`: $cssVal;"
                    }
                }
                '^(pt|pb|pl|pr|ps|pe|mt|mb|ml|mr)$' {
                    $propMapping = @{
                        'pt' = 'padding-top'; 'pb' = 'padding-bottom'; 'pl' = 'padding-left'; 'pr' = 'padding-right'; 
                        'ps' = 'padding-inline-start'; 'pe' = 'padding-inline-end';
                        'mt' = 'margin-top'; 'mb' = 'margin-bottom'; 'ml' = 'margin-left'; 'mr' = 'margin-right'
                    }
                    
                    if (-not $propMapping.ContainsKey($prop)) { return "" }
                    $cssProp = $propMapping[$prop]
                    
                    if (-not $TailwindMap.spacing.ContainsKey($value)) { return "" }
                    $spacingValue = $TailwindMap.spacing[$value]
                    if ($null -eq $spacingValue) { return "" }
                    
                    $cssVal = if ($isNegative) { "-$spacingValue" } else { $spacingValue }
                    $cssPropertyValue = "$cssProp`: $cssVal;"
                }
                '^(px|py|mx|my)$' {
                    $cssProps = @{
                        'px' = @('padding-left', 'padding-right'); 'py' = @('padding-top', 'padding-bottom');
                        'mx' = @('margin-left', 'margin-right'); 'my' = @('margin-top', 'margin-bottom')
                    }[$prop]
                    if ($TailwindMap.spacing.ContainsKey($value)) {
                        $cssVal = if ($isNegative) { "-$($TailwindMap.spacing[$value])" } else { $TailwindMap.spacing[$value] }
                        $cssPropertyValue = "$($cssProps[0]): $cssVal; $($cssProps[1]): $cssVal;"
                    }
                }
                '^(bg|text|border|fill|stroke|accent|outline|decoration)$' {
                    $cssProp = @{
                        'bg' = 'background-color'; 'text' = 'color'; 'border' = 'border-color'; 'fill' = 'fill'; 'stroke' = 'stroke';
                        'accent' = 'accent-color'; 'outline' = 'outline-color'; 'decoration' = 'text-decoration-color'
                    }[$prop]
                    $colorName = $parts[1]
                    $shade = if ($parts.Count -gt 2) { $parts[2] } else { '' }
                    $colorValue = ''
                    if ($shade) {
                        $colorValue = $TailwindMap.colors[$colorName][$shade]
                    }
                    else {
                        $colorValue = $TailwindMap.colors[$colorName]
                    }
                    if ($colorValue) {
                        $cssPropertyValue = "${cssProp}: ${colorValue};"
                    }
                }
                'text' {
                    if ($TailwindMap.fontSizes.ContainsKey($value)) {
                        $sizeInfo = $TailwindMap.fontSizes[$value]
                        $cssPropertyValue = "font-size: $($sizeInfo[0]); line-height: $($sizeInfo[1]);"
                    }
                }
                # Add more switch cases for w, h, rounded, font, etc.
                default { Write-Warning "Utility pattern not recognized for '$utility'"; return "" }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($cssPropertyValue)) { return "" }

    # --- 2. Build the CSS selector and apply variants ---
    $selector = ".$ClassName"
    $mediaQuery = ''
    $pseudoClasses = [System.Collections.Generic.List[string]]::new()

    foreach ($variant in $variants) {
        if ($TailwindMap.breakpoints.ContainsKey($variant)) {
            $mediaQuery = "@media (min-width: $($TailwindMap.breakpoints[$variant]))"
        }
        elseif ($variant -eq 'dark') {
            $selector = ".dark $selector"
        }
        else {
            # Add other variants like hover, focus, active, etc.
            $pseudoClasses.Add(":$variant")
        }
    }
    $finalSelector = "$selector$(($pseudoClasses | Sort-Object) -join '')"

    # --- 3. Assemble the final CSS rule ---
    $indentedCss = $cssPropertyValue.Split(';') | Where-Object { $_ } | ForEach-Object { "    $_;" } | Out-String
    $cssRule = "$finalSelector {`n$($indentedCss.Trim())`n}"

    if ($mediaQuery) {
        $cssRule = "$mediaQuery {`n    $($cssRule.Replace("`n", "`n    "))`n}"
    }

    return $cssRule
}

