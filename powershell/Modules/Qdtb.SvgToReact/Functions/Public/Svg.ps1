<#
    .SYNOPSIS
    Generates the content for a React component from SVG content.
#>
function Convert-ComponentContent {
    param ([string]$svgContent, [string]$componentName)
    $svgInner = [regex]::Match($svgContent, '<svg[^>]*>(.*?)</svg>', 'Singleline').Groups[1].Value.Trim()
    $svgAttrs = [regex]::Match($svgContent, '<svg([^>]*)>').Groups[1].Value.Trim()
    $width = [regex]::Match($svgAttrs, 'width="(\d+)"').Groups[1].Value
    $height = [regex]::Match($svgAttrs, 'height="(\d+)"').Groups[1].Value
    if ($width -eq "") { 
        $width = 24 
    }
    else { 
        $svgAttrs = $svgAttrs -replace 'width="(\d+)"', ''
    }
    if ($height -eq "") { 
        $height = 24 
    }
    else {
        $svgAttrs = $svgAttrs -replace 'height="(\d+)"', ''
    }
    if (-not $svgInner -or -not $svgAttrs) { throw "Invalid SVG format" }
    $result = @"
import React from 'react';

interface ${componentName}Props {
    width?: number;
    height?: number;
    className?: string;
    props?: React.SVGProps<SVGSVGElement>;
}

export const ${componentName}: React.FC<${componentName}Props> = ({
    width = ${width},
    height = ${height},
    className = '',
    ...props
}) => {
    return (
        <svg
            width={width}
            height={height}
            className={className}
            ${svgAttrs}
            {...props}
        >
            ${svgInner}
        </svg>
    );
};
"@
    return $result
}

<#
    .SYNOPSIS
    This script checks all files in a folder for common SVG attributes and converts them to React attributes.
#>
function Convert-SvgAttributesReact {
    param([string]$svgContent)
    $svgAttributes = @{
        "stroke-linecap"  = "strokeLinecap"
        "stroke-linejoin" = "strokeLinejoin"
        "stroke-width"    = "strokeWidth"
        "fill-rule"       = "fillRule"
        "clip-rule"       = "clipRule"
        "clip-path"       = "clipPath"
    }
    foreach ($key in $svgAttributes.Keys) {
        $svgContent = $svgContent -replace $key, $svgAttributes[$key]
    }
    return $svgContent
}

<#
    .SYNOPSIS
    Converts SVG files to React components helper script.
    This script will convert all SVG files in a folder to React components.

    .PARAMETER path 
#>
function Convert-FolderSvgToReact {
    param ([string]$path = ".")
    Write-Host "Conversion started." -ForegroundColor Green
    $svgFiles = Get-ChildItem -Path $path -Filter *.svg
    if ($svgFiles.Count -eq 0) {
        Write-Host "No SVG files found." -ForegroundColor Yellow
        return
    }
    $iconDir = New-IconDirectory
    foreach ($file in $svgFiles) {
        try {
            $svgContent = Get-Content -Path $file.FullName -Raw
            $convertedContent = Convert-SvgAttributesReact -svgContent $svgContent
            $componentName = Convert-ToPascalCase $file.Name
            $componentContent = Convert-ComponentContent -svgContent $convertedContent -componentName $componentName
            $outputPath = Join-Path -Path $iconDir -ChildPath "$componentName.tsx"
            Set-Content -Path $outputPath -Value $componentContent
            Write-Host "Successfully converted $($file.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to convert $($file.Name): $_" -ForegroundColor Red
        }
    }
    Write-Host "Conversion ended." -ForegroundColor Green
}
