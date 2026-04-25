<#
.SYNOPSIS
Syncs a forked Git repository with its upstream, handling merge conflicts.
.EXAMPLE
Example usage (run in a PowerShell console with verbose output enabled):
`Sync-Fork -Verbose`
`Sync-Fork -ForkPath "C:\path\to\your\fork" -Verbose`
#>
function Sync-Fork {
    param (
        [string]$ForkPath = "." # Default to current directory
    )

    try {
        Write-Verbose "Checking Git status in '$ForkPath'." -Verbose
        $gitStatus = git -C $ForkPath status --porcelain
        if ($gitStatus) {
            Write-Error "Merge conflicts detected. Please resolve them before syncing."
            return
        }

        Write-Verbose "Fetching upstream changes." -Verbose
        git -C $ForkPath remote add upstream $(git -C $ForkPath remote get-url origin | ForEach-Object { $_ -replace 'github.com', 'github.com' -replace ':', ':' -replace '\.git', '' -replace '/([^\/]+)/([^\/]+)', '/$1/$2' }) 2>$null
        git -C $ForkPath fetch upstream

        Write-Verbose "Merging upstream changes into local branch." -Verbose
        $currentBranch = git -C $ForkPath rev-parse --abbrev-ref HEAD
        git -C $ForkPath merge upstream/$currentBranch --ff-only

        Write-Verbose "Pushing changes to origin." -Verbose
        git -C $ForkPath push origin $currentBranch

        Write-Verbose "Fork synced successfully." -Verbose

    }
    catch {
        Write-Error $_
    }
}
<#
    .SYNOPSIS
    Sets the repository path based on the operating system, fetches the latest changes, checks the status, pulls if no changes, and starts development jobs.
#>
function Start-MyProject {
    param (
        [switch]$RunInBackground
    )
    $repo = if ($IsWindows) { "C:\Users\nateb\Source\Repos\be-gccpilot03-py" } else { "/home/nwb/Source/Repos/be-gccpilot03-py" }
    Push-Location $repo
    git fetch
    $s = git status --porcelain
    if ($s) { $s } else { 
        write-host "pulling"
        git pull
    }
    Pop-Location
    if ($RunInBackground) {
        write-host a
        Push-Location "$repo\frontend"
        Start-Job { npm run dev 2>&1 }
        Pop-Location
        Push-Location "$repo\backend"
        Start-Job { uv run fastapi dev 2>&1 }
        Pop-Location
    }
    else {
        write-host b
        Push-Location "$repo\frontend"
        Start-Job { npm run dev }  | Receive-Job
        Pop-Location
        Push-Location "$repo\backend"
        Start-Job { uv run fastapi dev } | Receive-Job
        Pop-Location
    }
    push-location $repo
    Read-Host "Press Enter to exit"
}
<#
    .SYNOPSIS
    Get status of multiple git repositories.

    .NOTES
    * Check if it's a git repository
    * Get git status
    * Display different parts of status with different colors
#>
function Get-MyProjectGitStatus {
    # Array of repository paths to check
    $repoPaths = @(
        '/home/nwb/Source/Repos/nate-opensac.org'
        '/home/nwb/Source/Repos/be-gccpilot03-py'
        'C:\Users\nateb\Source\Repos\be-gccpilot03-py'
        'C:\Users\nateb\Source\Repos\nate-opensac.org'
        'C:\Users\nateb\Source\Repos\nate-learning-blocks'
    )

    function Get-GitRepositoryStatus {
        param (
            [string]$repoPath
        )
        if (-not (Test-Path $repoPath)) {
            Write-Host $repoPath -ForegroundColor Cyan
            Write-Host "Repository path does not exist!" -ForegroundColor Red
            return
        }

        try {
            Push-Location $repoPath
            $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
            if (-not $isGitRepo) {
                Write-Host "Not a git repository!" -ForegroundColor Red
                return
            }
            $gitStatus = git --no-pager status
            if ($gitStatus -eq "Your branch is up to date with 'origin/main'.") {
                Write-Host $repoPath "GOOD" -ForegroundColor Gray
                return
            }
            $gitStatus | ForEach-Object {
                switch -Regex ($_) {
                    '^On branch' { Write-Host $_ -ForegroundColor Green }
                    'Changes not staged for commit' { Write-Host $_ -ForegroundColor Yellow }
                    'Changes to be committed' { Write-Host $_ -ForegroundColor Blue }
                    'Untracked files' { Write-Host $_ -ForegroundColor Red }
                    'Your branch is ahead of' { Write-Host $_ -ForegroundColor Magenta }
                    'Your branch is behind' { Write-Host $_ -ForegroundColor Magenta }
                    'nothing to commit' { Write-Host $_ -ForegroundColor Green }
                    default { Write-Host $_ }
                }
            }
        }
        catch {
            Write-Host "Error checking git status: $($_.Exception.Message)" -ForegroundColor Red
        }
        finally {
            Pop-Location
        }
    }

    foreach ($path in $repoPaths) {
        Get-GitRepositoryStatus -repoPath $path
    }

    Read-Host "Press Enter to exit"
}

function Update-GitRepositories {
    <#
    .SYNOPSIS
        Recursively updates all Git repositories within a specified root folder.

    .DESCRIPTION
        This function finds all subdirectories containing a `.git` folder within the specified RootFolder,
        or the current directory by default. For each repository found, it checks for uncommitted changes.
        If no changes are present, it performs a `git fetch --all --prune` to get the latest remote branches
        and then a `git pull` on the current branch to merge changes. Repositories with uncommitted changes
        are skipped to prevent merge conflicts and data loss.

    .PARAMETER RootFolder
        The root directory to start the search for Git repositories. If this parameter is not provided,
        the script will use the current working directory.

    .EXAMPLE
        Update-GitRepositories
        # Finds and updates all Git repositories in the current directory and its subfolders.

    .EXAMPLE
        Update-GitRepositories -RootFolder "C:\Users\YourUser\Projects"
        # Finds and updates all Git repositories within the specified "Projects" folder.

    .NOTES
        Requires Git to be installed and available in the system's PATH. This is an advanced function
        (cmdlet) and can be saved as a `.psm1` module file or executed after being loaded into a session.
    #>
    [CmdletBinding()]
    param (
        [string]$RootFolder = (Get-Location).Path
    )
    $initialLocation = Get-Location
    try {
        git --version | Out-Null
    }
    catch {
        Write-Error "Git is not installed or not in your PATH. Please install Git to use this script."
        return
    }
    try {
        $resolvedRootFolder = (Get-Item -Path $RootFolder).FullName
    }
    catch {
        Write-Error "The specified root folder '$RootFolder' does not exist."
        return
    }
    Write-Host "Starting Git update and pull for repositories in: $resolvedRootFolder" -ForegroundColor Cyan
    $gitRepos = Get-ChildItem -Path $resolvedRootFolder -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
        Test-Path "$($_.FullName)\.git"
    }
    if ($gitRepos.Count -eq 0) {
        Write-Warning "No Git repositories found in '$resolvedRootFolder'."
        return
    }
    foreach ($repo in $gitRepos) {
        Write-Host "`nProcessing repository: $($repo.FullName)" -ForegroundColor Green
        try {
            Set-Location -Path $repo.FullName
            $status = git status --porcelain
            if ($status) {
                Write-Warning "Repository '$($repo.Name)' has uncommitted changes. Skipping pull to avoid conflicts."
                Write-Warning "Please commit or stash your changes in '$($repo.FullName)' manually."
                continue
            }
            Write-Host "  Fetching latest changes and pruning stale branches..."
            git fetch --all --prune | Out-Null
            Write-Host "  Pulling changes..."
            git pull
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Successfully pulled changes for '$($repo.Name)'." -ForegroundColor Green
            }
            else {
                Write-Warning "  Pull for '$($repo.Name)' encountered issues. Check the output above."
            }
        }
        catch {
            Write-Error "An error occurred while processing '$($repo.FullName)': $($_.Exception.Message)"
        }
        finally {
            Set-Location -Path $initialLocation
        }
    }
    Write-Host "`nGit update and pull process completed." -ForegroundColor Cyan
}

function Invoke-GitStatusCheck {
    <#
    .SYNOPSIS
        Recursively scans folders for git repositories, runs git fetch and git status,
        and outputs a summary table.

    .DESCRIPTION
        Invoke-GitStatusCheck finds git repositories within a given root path at a
        configurable depth, runs `git fetch` and `git status --short` on each, then
        prints a colour-coded summary table.

    .PARAMETER Path
        Root directory to start scanning. Defaults to the current directory.

    .PARAMETER Depth
        Controls how deep to search for git repositories:
        1 - Only the root folder itself
        2 - Root + 1 level deep  (direct children)
        3 - Root + 2 levels deep (grandchildren)

    .PARAMETER FetchTimeout
        Seconds to wait before timing out a `git fetch`. Defaults to 30.

    .PARAMETER SkipFetch
        Skip `git fetch` and only report local status (faster, offline-safe).

    .EXAMPLE
        Invoke-GitStatusCheck -Path ~/projects -Depth 2

    .EXAMPLE
        Invoke-GitStatusCheck -Depth 3 -SkipFetch
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string] $Path = $PWD,

        [Parameter(Position = 1)]
        [ValidateRange(1, 3)]
        [int] $Depth = 2,

        [int] $FetchTimeout = 30,

        [switch] $SkipFetch
    )

    # ── Helpers ────────────────────────────────────────────────────────────────

    function Find-GitRepos {
        param([string]$Root, [int]$MaxDepth)

        # Depth 1 → only root; Depth 2 → root + children; Depth 3 → +grandchildren
        $fsDepth = $MaxDepth - 1   # Convert to filesystem recursion depth

        $candidates = @($Root)

        if ($fsDepth -ge 1) {
            $candidates += Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue
        }
        if ($fsDepth -ge 2) {
            $candidates += Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue |
            Get-ChildItem -Directory -ErrorAction SilentlyContinue
        }

        # Return only those that contain a .git entry
        $candidates | Where-Object {
            $p = if ($_ -is [string]) { $_ } else { $_.FullName }
            Test-Path (Join-Path $p '.git')
        } | ForEach-Object {
            if ($_ -is [string]) { $_ } else { $_.FullName }
        } | Select-Object -Unique
    }

    function Invoke-GitFetch {
        param([string]$RepoPath)
        try {
            $job = Start-Job -ScriptBlock {
                param($p)
                Set-Location $p
                git fetch --quiet 2>&1
            } -ArgumentList $RepoPath

            $completed = Wait-Job $job -Timeout $FetchTimeout
            if ($null -eq $completed) {
                Stop-Job $job
                Remove-Job $job -Force
                return @{ Success = $false; Output = "Timed out after ${FetchTimeout}s" }
            }

            $output = Receive-Job $job
            $exitCode = $job.ChildJobs[0].JobStateInfo.State
            Remove-Job $job -Force
            return @{ Success = $true; Output = ($output -join ' ').Trim() }
        }
        catch {
            return @{ Success = $false; Output = $_.Exception.Message }
        }
    }

    function Get-GitStatusInfo {
        param([string]$RepoPath)

        $result = @{
            Branch         = '?'
            Ahead          = 0
            Behind         = 0
            Modified       = 0
            Staged         = 0
            Untracked      = 0
            Conflicted     = 0
            StatusRaw      = ''
            RemoteTracking = $true
        }

        try {
            Push-Location $RepoPath

            # Current branch
            $result.Branch = (git rev-parse --abbrev-ref HEAD 2>$null) ?? 'DETACHED'

            # Porcelain v2 gives richer info
            $lines = git status --porcelain=v2 --branch 2>$null

            foreach ($line in $lines) {
                if ($line -match '^# branch\.ab \+(\d+) -(\d+)') {
                    $result.Ahead = [int]$Matches[1]
                    $result.Behind = [int]$Matches[2]
                }
                elseif ($line -match '^# branch\.upstream') {
                    $result.RemoteTracking = $true
                }
                elseif ($line -match '^# branch\.head') {
                    # already captured via rev-parse
                }
                elseif ($line -match '^1 ') {
                    # ordinary changed entry — XY field
                    $xy = $line.Substring(2, 2)
                    if ($xy[0] -ne '.') { $result.Staged++ }
                    if ($xy[1] -ne '.') { $result.Modified++ }
                }
                elseif ($line -match '^2 ') {
                    $result.Staged++   # renamed / copied
                }
                elseif ($line -match '^u ') {
                    $result.Conflicted++
                }
                elseif ($line -match '^\? ') {
                    $result.Untracked++
                }
            }

            # Detect missing upstream
            $upstream = git rev-parse --abbrev-ref '@{upstream}' 2>$null
            $result.RemoteTracking = ($null -ne $upstream -and $upstream -ne '')
        }
        catch {
            $result.StatusRaw = $_.Exception.Message
        }
        finally {
            Pop-Location
        }

        return $result
    }

    function Get-StatusLabel {
        param($info)
        $parts = @()
        if ($info.Staged -gt 0) { $parts += "$($info.Staged) staged" }
        if ($info.Modified -gt 0) { $parts += "$($info.Modified) modified" }
        if ($info.Untracked -gt 0) { $parts += "$($info.Untracked) untracked" }
        if ($info.Conflicted -gt 0) { $parts += "$($info.Conflicted) conflicted" }
        if ($parts.Count -eq 0) { return 'Clean' }
        return $parts -join ', '
    }

    function Get-SyncLabel {
        param($info)
        if (-not $info.RemoteTracking) { return 'No upstream' }
        if ($info.Ahead -gt 0 -and $info.Behind -gt 0) { return "↑$($info.Ahead) ↓$($info.Behind)" }
        if ($info.Ahead -gt 0) { return "↑$($info.Ahead) ahead" }
        if ($info.Behind -gt 0) { return "↓$($info.Behind) behind" }
        return 'In sync'
    }

    # ── Main ───────────────────────────────────────────────────────────────────

    $rootResolved = (Resolve-Path $Path).Path
    Write-Host "`n🔍 Scanning: $rootResolved  (depth $Depth)" -ForegroundColor Cyan

    $repos = Find-GitRepos -Root $rootResolved -MaxDepth $Depth

    if ($repos.Count -eq 0) {
        Write-Warning "No git repositories found at depth $Depth under: $rootResolved"
        return
    }

    Write-Host "   Found $($repos.Count) repo(s)`n" -ForegroundColor Cyan

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $counter = 0

    foreach ($repo in $repos) {
        $counter++
        $relPath = $repo.Replace($rootResolved, '').TrimStart([IO.Path]::DirectorySeparatorChar)
        if ($relPath -eq '') { $relPath = '.' }

        Write-Host "  [$counter/$($repos.Count)] $relPath" -NoNewline

        # --- fetch ---
        $fetchStatus = 'Skipped'
        if (-not $SkipFetch) {
            Write-Host ' → fetching...' -NoNewline
            $fetchResult = Invoke-GitFetch -RepoPath $repo
            $fetchStatus = if ($fetchResult.Success) { 'OK' } else { "FAIL: $($fetchResult.Output)" }
        }

        Write-Host ''  # newline

        # --- status ---
        $info = Get-GitStatusInfo -RepoPath $repo

        $localLabel = Get-StatusLabel -info $info
        $syncLabel = Get-SyncLabel  -info $info

        $results.Add([PSCustomObject]@{
                Repo           = $relPath
                Branch         = $info.Branch
                Fetch          = $fetchStatus
                Local          = $localLabel
                Sync           = $syncLabel
                Staged         = $info.Staged
                Modified       = $info.Modified
                Untracked      = $info.Untracked
                Conflicted     = $info.Conflicted
                Ahead          = $info.Ahead
                Behind         = $info.Behind
                NeedsAttention = ($localLabel -ne 'Clean' -or $syncLabel -notin @('In sync', 'Skipped', 'No upstream' ))
            })
    }

    # ── Summary table ──────────────────────────────────────────────────────────

    $divider = '─' * 100
    Write-Host "`n$divider" -ForegroundColor DarkGray
    Write-Host ' GIT STATUS SUMMARY' -ForegroundColor White
    Write-Host "$divider`n" -ForegroundColor DarkGray

    foreach ($r in $results) {
        # Pick row colour
        $rowColor = if ($r.Conflicted -gt 0) { 'Red' }
        elseif ($r.NeedsAttention) { 'Yellow' }
        else { 'Green' }

        $fetchColor = if ($r.Fetch -like 'FAIL*') { 'Red' } elseif ($r.Fetch -eq 'OK') { 'Green' } else { 'DarkGray' }

        Write-Host ('  {0,-40} ' -f $r.Repo)         -NoNewline -ForegroundColor $rowColor
        Write-Host ('{0,-18} ' -f $r.Branch)        -NoNewline -ForegroundColor Cyan
        Write-Host ('Fetch:{0,-10} ' -f $r.Fetch)     -NoNewline -ForegroundColor $fetchColor
        Write-Host ('Local:{0,-30} ' -f $r.Local)     -NoNewline -ForegroundColor $rowColor
        Write-Host ('Sync:{0}' -f $r.Sync)                    -ForegroundColor $rowColor
    }

    Write-Host "`n$divider" -ForegroundColor DarkGray

    # Aggregate stats
    $clean = ($results | Where-Object { $_.Local -eq 'Clean' -and $_.Sync -in @('In sync', 'No upstream') }).Count
    $dirty = ($results | Where-Object { $_.Local -ne 'Clean' }).Count
    $outOfSync = ($results | Where-Object { $_.Sync -notin @('In sync', 'No upstream', 'Skipped') }).Count
    $fetchFailed = ($results | Where-Object { $_.Fetch -like 'FAIL*' }).Count

    Write-Host ("`n  Repos scanned : {0}" -f $results.Count)   -ForegroundColor White
    Write-Host ("  ✔  Clean       : {0}" -f $clean)             -ForegroundColor Green
    Write-Host ("  ⚠  Dirty       : {0}" -f $dirty)             -ForegroundColor Yellow
    Write-Host ("  ↕  Out of sync : {0}" -f $outOfSync)         -ForegroundColor Yellow
    Write-Host ("  ✘  Fetch errors: {0}" -f $fetchFailed)       -ForegroundColor $(if ($fetchFailed -gt 0) { 'Red' } else { 'DarkGray' })
    Write-Host ''

    # Return the data for piping
    return $results
}
