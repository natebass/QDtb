<#
    .SYNOPSIS
    Expands one cron field into the set of numbers it matches.

    .DESCRIPTION
    Understands *, a, a-b, a-b/n, */n and comma separated lists of any of those.
    Names (jan, mon, ...) are translated by the caller before this runs.
#>
function Expand-ClaudeCronField {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,

        [Parameter(Mandatory = $true)]
        [int]$Min,

        [Parameter(Mandatory = $true)]
        [int]$Max
    )
    $values = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($part in $Field.Split(',')) {
        $item = $part.Trim()
        if ([string]::IsNullOrWhiteSpace($item)) { throw "Empty element in cron field '$Field'." }

        $step = 1
        if ($item.Contains('/')) {
            $split = $item.Split('/')
            if ($split.Count -ne 2) { throw "Malformed step in cron field '$item'." }
            $item = $split[0]
            if (-not [int]::TryParse($split[1], [ref]$step) -or $step -lt 1) {
                throw "Step must be a positive number in cron field '$part'."
            }
        }

        $from = $Min
        $to = $Max
        if ($item -ne '*') {
            if ($item.Contains('-')) {
                $range = $item.Split('-')
                if ($range.Count -ne 2) { throw "Malformed range in cron field '$part'." }
                $from = [int]$range[0]
                $to = [int]$range[1]
            }
            else {
                $from = [int]$item
                # A bare number with a step means "from here to the end", as in 5/10.
                $to = if ($part.Contains('/')) { $Max } else { $from }
            }
        }

        if ($from -lt $Min -or $to -gt $Max -or $from -gt $to) {
            throw "Cron field '$part' is outside the allowed range $Min-$Max."
        }
        for ($i = $from; $i -le $to; $i += $step) { [void]$values.Add($i) }
    }
    return ($values | Sort-Object)
}

<#
    .SYNOPSIS
    Parses a five field cron expression, or one of the @ macros, into matchable sets.
#>
function ConvertFrom-ClaudeCronExpression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Expression
    )
    $text = $Expression.Trim().ToLowerInvariant()
    $macros = @{
        '@yearly'   = '0 0 1 1 *'
        '@annually' = '0 0 1 1 *'
        '@monthly'  = '0 0 1 * *'
        '@weekly'   = '0 0 * * 0'
        '@daily'    = '0 0 * * *'
        '@midnight' = '0 0 * * *'
        '@hourly'   = '0 * * * *'
    }
    if ($macros.ContainsKey($text)) { $text = $macros[$text] }

    $months = @{ jan = 1; feb = 2; mar = 3; apr = 4; may = 5; jun = 6; jul = 7; aug = 8; sep = 9; oct = 10; nov = 11; dec = 12 }
    $days = @{ sun = 0; mon = 1; tue = 2; wed = 3; thu = 4; fri = 5; sat = 6 }

    $fields = $text -split '\s+' | Where-Object { $_ }
    if ($fields.Count -ne 5) {
        throw "A cron expression needs 5 fields (minute hour day month weekday); got $($fields.Count) from '$Expression'."
    }

    $monthField = $fields[3]
    foreach ($name in $months.Keys) { $monthField = $monthField -replace $name, $months[$name] }
    $dayField = $fields[4]
    foreach ($name in $days.Keys) { $dayField = $dayField -replace $name, $days[$name] }

    # Cron accepts both 0 and 7 for Sunday, so expand over 0-7 and fold 7 back to 0.
    $weekdays = @(Expand-ClaudeCronField -Field $dayField -Min 0 -Max 7) |
        ForEach-Object { if ($_ -eq 7) { 0 } else { $_ } } |
        Sort-Object -Unique

    return [pscustomobject]@{
        Expression       = $Expression
        Minutes          = @(Expand-ClaudeCronField -Field $fields[0] -Min 0 -Max 59)
        Hours            = @(Expand-ClaudeCronField -Field $fields[1] -Min 0 -Max 23)
        DaysOfMonth      = @(Expand-ClaudeCronField -Field $fields[2] -Min 1 -Max 31)
        Months           = @(Expand-ClaudeCronField -Field $monthField -Min 1 -Max 12)
        DaysOfWeek       = @($weekdays)
        DayOfMonthIsWild = ($fields[2].Trim() -eq '*')
        DayOfWeekIsWild  = ($dayField.Trim() -eq '*')
    }
}

<#
    .SYNOPSIS
    Returns the first moment at or after -After that satisfies the cron expression.

    .DESCRIPTION
    Days that cannot match are skipped whole, so a yearly expression still resolves
    quickly. Search gives up after two years, which only happens for impossible dates
    such as 30 February.
#>
function Get-ClaudeCronNextRun {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Expression,

        [Parameter(Mandatory = $false)]
        [datetime]$After = (Get-Date)
    )
    $schedule = ConvertFrom-ClaudeCronExpression -Expression $Expression
    # Cron has minute resolution; start from the next whole minute.
    $cursor = $After.AddSeconds(60 - $After.Second).AddMilliseconds( - $After.Millisecond)
    $cursor = [datetime]::new($cursor.Year, $cursor.Month, $cursor.Day, $cursor.Hour, $cursor.Minute, 0, $cursor.Kind)
    $limit = $After.AddYears(2)

    while ($cursor -lt $limit) {
        $dayMatches = if ($schedule.DayOfMonthIsWild -and $schedule.DayOfWeekIsWild) {
            $true
        }
        elseif ($schedule.DayOfMonthIsWild) {
            $schedule.DaysOfWeek -contains [int]$cursor.DayOfWeek
        }
        elseif ($schedule.DayOfWeekIsWild) {
            $schedule.DaysOfMonth -contains $cursor.Day
        }
        else {
            # Classic cron: when both are restricted either one may match.
            ($schedule.DaysOfMonth -contains $cursor.Day) -or ($schedule.DaysOfWeek -contains [int]$cursor.DayOfWeek)
        }

        if (-not ($dayMatches -and ($schedule.Months -contains $cursor.Month))) {
            $cursor = $cursor.Date.AddDays(1)
            continue
        }
        if ($schedule.Hours -notcontains $cursor.Hour) {
            $cursor = $cursor.Date.AddHours($cursor.Hour + 1)
            continue
        }
        if ($schedule.Minutes -contains $cursor.Minute) { return $cursor }
        $cursor = $cursor.AddMinutes(1)
    }
    throw "Cron expression '$Expression' has no match within the next two years."
}

<#
    .SYNOPSIS
    Turns friendly interval text such as '90m', '2h30m' or '1d' into a TimeSpan.
#>
function ConvertTo-ClaudeCronTimeSpan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Interval
    )
    $text = ($Interval -replace '\s', '').ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($text)) { throw 'Interval cannot be empty.' }

    # A bare number is read as minutes, which is what people mean by "every 30".
    $number = 0.0
    if ([double]::TryParse($text, [ref]$number)) { return [timespan]::FromMinutes($number) }

    if ($text -notmatch '^(\d+(?:\.\d+)?[dhms])+$') {
        throw "Could not read '$Interval' as an interval. Try forms like 30m, 2h, 2h30m or 1d."
    }
    $matched = [regex]::Matches($text, '(\d+(?:\.\d+)?)([dhms])')

    $total = [timespan]::Zero
    foreach ($match in $matched) {
        $value = [double]$match.Groups[1].Value
        switch ($match.Groups[2].Value) {
            'd' { $total += [timespan]::FromDays($value) }
            'h' { $total += [timespan]::FromHours($value) }
            'm' { $total += [timespan]::FromMinutes($value) }
            's' { $total += [timespan]::FromSeconds($value) }
        }
    }
    if ($total -le [timespan]::Zero) { throw 'Interval must be greater than zero.' }
    return $total
}

<#
    .SYNOPSIS
    Works out when a job should next become eligible after a run finishes.

    .DESCRIPTION
    Returns $null for one-shot jobs, which tells the runner to retire them.
#>
function Get-ClaudeCronFollowUp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Job,

        [Parameter(Mandatory = $false)]
        [datetime]$From = (Get-Date)
    )
    if ($Job.Cron) { return (Get-ClaudeCronNextRun -Expression $Job.Cron -After $From) }
    if ($Job.IntervalSeconds) { return $From.AddSeconds([double]$Job.IntervalSeconds) }
    return $null
}
