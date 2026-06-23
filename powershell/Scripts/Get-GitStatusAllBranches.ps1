#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$GitDirectory = (Get-Location).Path
)

<#
.SYNOPSIS
    Check git status of all branches
.DESCRIPTION
    Fetches all remote branches, pulls current branch, and shows status of all branches
.PARAMETER GitDirectory
    The path to the git repository directory. Defaults to current directory.
.EXAMPLE
    ./Get-GitStatusAllBranches.ps1
.EXAMPLE
    ./Get-GitStatusAllBranches.ps1 ~/Source/Repos/my-repo
.EXAMPLE
    gnome-terminal --geometry=80x56+2200 -- bash -c "pwsh -Command '& ~/.local/share/powershell/Scripts/Get-GitStatusAllBranches.ps1 ~/Source/Repos/fe-innovcal-web'; exec fish"
#>
function Get-GitStatusAllBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$RepoPath
    )

    $originalLocation = Get-Location
    try {
        Set-Location $RepoPath -ErrorAction Stop

        $gitDir = git rev-parse --git-dir 2>$null
        if (-not (Test-Path ".git") -and -not $gitDir) {
            throw "Not a git repository: $RepoPath"
        }

        Write-Information "=== Working in repository: $RepoPath ===" -ForegroundColor Magenta
        Write-Information ""

        Write-Information "=== Fetching all remote branches ===" -ForegroundColor Green
        $null = git fetch --all
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to fetch remote branches"
        }

        Write-Information "`n=== Getting current branch ===" -ForegroundColor Green
        $currentBranch = git branch --show-current
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get current branch"
        }

        Write-Information "Current branch: $currentBranch" -ForegroundColor Yellow

        Write-Information "`n=== Pulling current branch ===" -ForegroundColor Green
        $null = git pull origin $currentBranch
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to pull current branch $currentBranch"
        }

        Write-Information "`n=== Getting all branches (local and remote) ===" -ForegroundColor Green
        $allBranches = git branch -a |
            Where-Object { $_ -notmatch 'HEAD' } |
            ForEach-Object { $_.Trim() -replace '^\*\s*', '' -replace '^remotes/origin/', '' } |
            Sort-Object -Unique

        Write-Information "`n=== Checking status of all branches ===" -ForegroundColor Green

        foreach ($branch in $allBranches) {
            Write-Information "`n--- Branch: $branch ---" -ForegroundColor Cyan

            $null = git show-ref --verify --quiet "refs/heads/$branch" 2>$null
            if ($LASTEXITCODE -eq 0) {
                $null = git checkout $branch *>$null

                if ($LASTEXITCODE -eq 0) {
                    $null = git pull origin $branch *>$null

                    Write-Information "Status:" -ForegroundColor White
                    $status = git status --porcelain
                    if ($status) {
                        $status | ForEach-Object { Write-Information "  $_" }
                    }
                    else {
                        Write-Information "  Clean working directory" -ForegroundColor Green
                    }

                    $upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
                    if ($LASTEXITCODE -eq 0 -and $upstream) {
                        $aheadBehind = git rev-list --left-right --count "HEAD...$upstream" 2>$null
                        if ($LASTEXITCODE -eq 0 -and $aheadBehind) {
                            $counts = $aheadBehind -split '\s+'
                            if ($counts.Length -eq 2) {
                                $ahead = $counts[0]
                                $behind = $counts[1]
                                if ($ahead -gt 0 -or $behind -gt 0) {
                                    Write-Information "  Commits ahead: $ahead, behind: $behind" -ForegroundColor Yellow
                                }
                                else {
                                    Write-Information "  Up to date with remote" -ForegroundColor Green
                                }
                            }
                        }
                    }
                }
                else {
                    Write-Information "Error: Could not checkout branch $branch" -ForegroundColor Red
                }
            }
            else {
                Write-Information "Branch exists only on remote - not checked out locally" -ForegroundColor Magenta
            }
        }

        Write-Information "`n=== Returning to original branch ===" -ForegroundColor Green
        $null = git checkout $currentBranch *>$null

        Write-Information "`n=== Summary completed ===" -ForegroundColor Green
    }
    catch {
        Write-Error $_.Exception.Message
    }
    finally {
        Set-Location $originalLocation
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($GitDirectory.StartsWith('~')) {
        $GitDirectory = $GitDirectory -replace '^~', $env:HOME
    }

    Get-GitStatusAllBranches -RepoPath $GitDirectory
}
