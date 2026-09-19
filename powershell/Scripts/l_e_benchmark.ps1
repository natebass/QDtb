[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RepoPath = "C:\Users\nateb\Source\Repos\openfresno.org"
)

function Get-FileLineEndingTally_Old {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path,

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
    $TotalFiles = 0
    
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue -Exclude $ExcludedDirectories | ForEach-Object {
        $TotalFiles++
        try {
            $FileContent = Get-Content $_.FullName -Raw -Encoding UTF8
            $EndingsFound = @()
            if ($FileContent -match "`r`n") { $EndingsFound += "CRLF" }
            if ($FileContent -match "(?<!`r)`n") { $EndingsFound += "LF" }
            if ($FileContent -match "`r(?!`n)") { $EndingsFound += "CR" }
            $EndingType = switch ($EndingsFound.Count) { 0 { "None" } 1 { $EndingsFound[0] } default { "Mixed" } }
            $LineEndingTally.$EndingType++
        }
        catch { 
            $LineEndingTally.None++ 
        }
    }
    return [PSCustomObject]@{Tally = $LineEndingTally; TotalFiles = $TotalFiles }
}

function Get-FileLineEndingTally_New {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path,

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
    
    $topLevelFiles = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
    
    $dirsToSearch = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -notin $ExcludedDirectories }
    
    $subFiles = $dirsToSearch | Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue
    
    $allFiles = $topLevelFiles + $subFiles
    $TotalFiles = $allFiles.Count

    $allFiles | ForEach-Object {
        try {
            $FileContent = Get-Content $_.FullName -Raw -Encoding UTF8
            $EndingsFound = @()
            if ($FileContent -match "`r`n") { $EndingsFound += "CRLF" }
            if ($FileContent -match "(?<!`r)`n") { $EndingsFound += "LF" }
            if ($FileContent -match "`r(?!`n)") { $EndingsFound += "CR" }
            $EndingType = switch ($EndingsFound.Count) { 0 { "None" } 1 { $EndingsFound[0] } default { "Mixed" } }
            $LineEndingTally.$EndingType++
        }
        catch { 
            $LineEndingTally.None++ 
        }
    }
    
    $searchedDirNames = $dirsToSearch.Name
    return [PSCustomObject]@{Tally = $LineEndingTally; TotalFiles = $TotalFiles; SearchedDirs = $searchedDirNames }
}

# --- Main Benchmark Logic ---

if (-not (Test-Path $RepoPath)) {
    Write-Error "Path not found: $RepoPath"
    return
}

$ExcludedDirs = @(
    "node_modules", "out", ".next", "storybook-static", ".git",
    "bin", "obj", ".cache", "dist", "build"
)

Write-Host "Starting benchmark on '$RepoPath'..." -ForegroundColor Cyan
Write-Host "Excluded Directories: $($ExcludedDirs -join ', ')"

# --- Benchmark 1: Old Method ---
Write-Host "`nRunning OLD method (Recurse -Exclude)..." -ForegroundColor Yellow
$oldBenchmark = Measure-Command {
    $oldResult = Get-FileLineEndingTally_Old -Path $RepoPath -ExcludedDirectories $ExcludedDirs
}

# --- Benchmark 2: New Method ---
Write-Host "Running NEW method (Filter Dirs then Recurse)..." -ForegroundColor Green
$newBenchmark = Measure-Command {
    $newResult = Get-FileLineEndingTally_New -Path $RepoPath -ExcludedDirectories $ExcludedDirs
}

# --- Get Total Dirs for context ---
$allTopLevelDirs = (Get-ChildItem -Path $RepoPath -Directory -ErrorAction SilentlyContinue).Name
$skippedDirs = $allTopLevelDirs | Where-Object { $_ -in $ExcludedDirs }

# --- Print Summary ---
Write-Host "`n--- Benchmark Summary ---" -ForegroundColor Cyan

Write-Host "`n[OLD METHOD: Recurse -Exclude]" -ForegroundColor Yellow
Write-Host "Time Taken: $($oldBenchmark.TotalSeconds.ToString('F2')) seconds"
Write-Host "Files Found: $($oldResult.TotalFiles)"
Write-Host "Directories Traversed: ALL $($allTopLevelDirs.Count) (PowerShell still enters excluded dirs to check)"

Write-Host "`n[NEW METHOD: Filter Dirs then Recurse]" -ForegroundColor Green
Write-Host "Time Taken: $($newBenchmark.TotalSeconds.ToString('F2')) seconds"
Write-Host "Files Found: $($newResult.TotalFiles)"
Write-Host "Directories Traversed: $($newResult.SearchedDirs.Count) / $($allTopLevelDirs.Count)"
Write-Host "  Searched: $($newResult.SearchedDirs -join ', ')"
Write-Host "  Skipped:  $($skippedDirs -join ', ')"

# --- Final Verdict ---
if ($oldBenchmark.TotalSeconds -gt 0) {
    $timeDiff = $oldBenchmark.TotalSeconds - $newBenchmark.TotalSeconds
    $percentFaster = ($timeDiff / $oldBenchmark.TotalSeconds) * 100
    Write-Host "`nResult: The new method was $($timeDiff.ToString('F2')) seconds faster ($($percentFaster.ToString('F0'))% faster)." -ForegroundColor White
}
else {
    Write-Host "`nResult: Both methods were too fast to compare meaningfully." -ForegroundColor White
}

