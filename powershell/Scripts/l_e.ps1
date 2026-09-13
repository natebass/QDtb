function Get-FileLineEndingTally {
    <#
    .SYNOPSIS
    Tally line endings in files under a path and optionally return files matching a specific ending type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path,

        [Parameter()]
        [ValidateSet("None", "Mixed", "LF", "CR", "CRLF")]
        [string]$Filter,

        [string[]]$ExcludedDirectories = @(
            "node_modules",
            "out",
            ".next",
            "storybook-static",
            ".git",
            "bin",
            "obj",
            ".cache",
            "dist",
            "build"
        )
    )
    $LineEndingTally = @{CRLF = 0; LF = 0; CR = 0; Mixed = 0; None = 0 }
    # Use ArrayList for reliable in-place appends
    $FileMatches = @{
        CRLF  = [System.Collections.ArrayList]::new()
        LF    = [System.Collections.ArrayList]::new()
        CR    = [System.Collections.ArrayList]::new()
        Mixed = [System.Collections.ArrayList]::new()
        None  = [System.Collections.ArrayList]::new()
    }

    $topLevelFiles = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue

    $subFiles = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin $ExcludedDirectories } |
    Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue

    ($topLevelFiles + $subFiles) | ForEach-Object {
        try {
            $FileContent = Get-Content $_.FullName -Raw -Encoding UTF8
            $EndingsFound = @()

            if ($FileContent -match "`r`n") { $EndingsFound += "CRLF" }
            if ($FileContent -match "(?<!`r)`n") { $EndingsFound += "LF" }
            if ($FileContent -match "`r(?!`n)") { $EndingsFound += "CR" }

            $EndingType = switch ($EndingsFound.Count) { 0 { "None" } 1 { $EndingsFound[0] } default { "Mixed" } }
            $LineEndingTally.$EndingType++
            # Append to the ArrayList stored in the hashtable
            $FileMatches[$EndingType].Add($_.FullName) | Out-Null
        }
        catch {
            Write-Warning "Could not read: $($_.FullName)"
            $LineEndingTally.None++
            $FileMatches.None.Add($_.FullName) | Out-Null
        }
    }

    if ($PSBoundParameters.ContainsKey('Filter')) {
        $files = @()
        if ($FileMatches.ContainsKey($Filter)) {
            $files = [array]$FileMatches[$Filter]
        }

        [PSCustomObject]@{
            Ending = $Filter
            Count  = $files.Count
            Files  = $files
        }
    }
    else {
        # Preserve original-like output: produce objects with "Line ending" and "Count" columns
        $order = @('None', 'Mixed', 'LF', 'CR', 'CRLF')
        $out = foreach ($k in $order) {
            [PSCustomObject]@{
                'Line ending' = $k
                'Count'       = $LineEndingTally[$k]
            }
        }
        $out
    }
}

Get-FileLineEndingTally -Filter CRLF | ConvertTo-Json -Depth 5