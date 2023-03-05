<#
.SYNOPSIS
  Resynchronization of timstamps with time-translation table
#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "File describing the timetable")][string] $TimetableFile,
    [Parameter(Mandatory = $true, HelpMessage = "File containing the timestamps to resynchronize")][string] $FileToProcess)


function GetDateFrom {
    param (
        [string] $stringValue
    )
    Write-Host $stringValue
    if ($readLine -match '^(.*?)-->') {
        $date = ($Matches.1).Trim()
        Write-Host $date
        return [datetime]::parseexact($date, 'hh:mm:ss,fff', $null)
    }
}

function GetDateTo {
    param (
        [string] $stringValue
    )
    if ($readLine -match '-->(.*),?.*$') {
        $date = ($Matches.1).Trim()
        return [datetime]::parseexact($date, 'hh:mm:ss,fff', $null)
    }
}

function ConvertTime {
    param (
        [DateTime] $timeToConvert
    )

    Write-Host "Compare $timeToConvert with " + $timeTable[$indexTimeTable + 1].From

    while ($timeToConvert -gt $timeTable[$indexTimeTable + 1].From) {
        Write-Host ">>> Next index "  
        $from = $timeTable[$indexTimeTable + 1].From
        Write-Host "FROM = $from"
        $indexTimeTable++
    }    
    Write-Host $timeTable[$indexTimeTable]
}

#
# Main program
# -------------

## Read timetable file
$global:timeTable = @()
Write-Host "Read timetable"

Get-Content $TimetableFile |
ForEach-Object {

    $fromDate = GetDateFrom $_
    $toDate = GetDateTo $_

    $timeTable += @{ From = $fromDate; To = $toDate }
}

$currentIndexInTimeTable = 0

## Update timestamps and re-write it to the console

Get-Content $FileToProcess |
ForEach-Object {
    $readLine = $_
    Write-Host "------------- Read srt: <$readLine>"
    if ($readLine -match '-->') {  # Timestamp Row
        $date = GetDateFrom $readLine
        ConvertTime -timeToConvert $date

    } else {
        Write-Output $_
    }
}
