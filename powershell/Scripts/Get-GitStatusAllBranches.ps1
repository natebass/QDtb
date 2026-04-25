#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateScript({ Test-Path $_ })]
    [string]$GitDirectory = (Get-Location)
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
function Get-GitStatusAllBranches {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$RepoPath
    )
    
    # Use try-finally to ensure we return to original location
    $originalLocation = Get-Location
    try {
        # Validate and change to the specified directory
        Set-Location $RepoPath -ErrorAction Stop
        
        # Check if it's a git repository
        if (-not (Test-Path ".git") -and -not (git rev-parse --git-dir 2>$null)) {
            throw "Not a git repository: $RepoPath"
        }
        
        Write-Host "=== Working in repository: $RepoPath ===" -ForegroundColor Magenta
        Write-Host ""
        
        # Fetch all remote branches
        Write-Host "=== Fetching all remote branches ===" -ForegroundColor Green
        $null = git fetch --all
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to fetch remote branches"
        }
        
        # Get and pull current branch
        Write-Host "`n=== Getting current branch ===" -ForegroundColor Green
        $currentBranch = git branch --show-current
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get current branch"
        }
        
        Write-Host "Current branch: $currentBranch" -ForegroundColor Yellow
        
        Write-Host "`n=== Pulling current branch ===" -ForegroundColor Green
        $null = git pull origin $currentBranch
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to pull current branch $currentBranch"
        }
        
        # Get all unique branch names
        Write-Host "`n=== Getting all branches (local and remote) ===" -ForegroundColor Green
        $allBranches = git branch -a | 
            Where-Object { $_ -notmatch 'HEAD' } |
            ForEach-Object { $_.Trim() -replace '^\*\s*', '' -replace '^remotes/origin/', '' } |
            Sort-Object -Unique
        
        Write-Host "`n=== Checking status of all branches ===" -ForegroundColor Green
        
        foreach ($branch in $allBranches) {
            Write-Host "`n--- Branch: $branch ---" -ForegroundColor Cyan
            
            # Check if branch exists locally
            $localBranchExists = git show-ref --verify --quiet "refs/heads/$branch" 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                # Switch to the branch
                $null = git checkout $branch *>$null
                
                if ($LASTEXITCODE -eq 0) {
                    # Try to pull the branch
                    $null = git pull origin $branch *>$null
                    
                    # Show status
                    Write-Host "Status:" -ForegroundColor White
                    $status = git status --porcelain
                    if ($status) {
                        $status | ForEach-Object { Write-Host "  $_" }
                    } else {
                        Write-Host "  Clean working directory" -ForegroundColor Green
                    }
                    
                    # Show commits ahead/behind
                    $upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
                    if ($LASTEXITCODE -eq 0 -and $upstream) {
                        $aheadBehind = git rev-list --left-right --count "HEAD...$upstream" 2>$null
                        if ($LASTEXITCODE -eq 0 -and $aheadBehind) {
                            $counts = $aheadBehind -split '\s+'
                            if ($counts.Length -eq 2) {
                                $ahead = $counts[0]
                                $behind = $counts[1]
                                if ($ahead -gt 0 -or $behind -gt 0) {
                                    Write-Host "  Commits ahead: $ahead, behind: $behind" -ForegroundColor Yellow
                                } else {
                                    Write-Host "  Up to date with remote" -ForegroundColor Green
                                }
                            }
                        }
                    }
                }
                else {
                    Write-Host "Error: Could not checkout branch $branch" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Branch exists only on remote - not checked out locally" -ForegroundColor Magenta
            }
        }
        
        Write-Host "`n=== Returning to original branch ===" -ForegroundColor Green
        $null = git checkout $currentBranch *>$null
        
        Write-Host "`n=== Summary completed ===" -ForegroundColor Green
    }
    catch {
        Write-Error $_.Exception.Message
    }
    finally {
        Set-Location $originalLocation
    }
}

# Run the function if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    # Expand tilde to home directory if present
    if ($GitDirectory.StartsWith('~')) {
        $GitDirectory = $GitDirectory -replace '^~', $env:HOME
    }
    
    Get-GitStatusAllBranches -RepoPath $GitDirectory
}
