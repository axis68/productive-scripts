<#
.SYNOPSIS
  Process and update timestamp files file
#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "Filename timestamp filess")][string] $File,
    [Parameter(Mandatory = $false, HelpMessage = "Operation: Reindex starting with, exemple: Reindex 30is35")][string] $Reindex = "",
    [Parameter(Mandatory = $false, HelpMessage = "Operation: read and apply time stamps from reference file")][string] $SetTimingFromReferenceFile,
    [Parameter(Mandatory = $false, HelpMessage = "Check whether each timestamp files is having an index and a timing")][switch] $CheckContent = $false)

# Reindexation option

[int] $replaceIndex = -1
[int] $replaceIndexWith = -1
[bool] $isReplacingIndex = $false
if ($Reindex -match '^[0-9]+is[0-9]+$') {
    Write-Host "Option reindex selected"
    $replaceIndex = $Reindex -replace 'is[0-9]+$'
    $replaceIndexWith = $Reindex -replace '^[0-9]+is'
}

#
# Main program
# -------------

## Read reference file
$allTimingReferenceFile = @{}
$currentIndex = -1 
if ($SetTimingFromReferenceFile.Length -gt 0) {
    Get-Content $SetTimingFromReferenceFile |
    ForEach-Object {
        if ($_ -match '^[0-9]+$') {  # Index
            $currentIndex = $_
        }
        if ($_ -match '-->') {
            if ($currentIndex -eq -1) {
                Write-Error "Invalid timestamp file: timestamp $_ not preceeded by an index"
            } else {
                $allTimingReferenceFile.Add($currentIndex, $_)
            }
        }
    }
}

# Check initialization

$timestampHasIndex = $true
$timestampHasTiming = $true

## Apply main file

Get-Content $File |
ForEach-Object {
    if ($_ -match '^[0-9]+$') {             # Index row
        if ($CheckContent) {
            if (-not ($timestampHasIndex -and $timestampHasTiming) ) {
                Write-Host "Check: Index $currentIndex invalid: probably time missing"
            }
            $timestampHasTiming = $false
        }
        $currentIndex = $_
        if ($_ -eq $replaceIndex) {
            $isReplacingIndex = $true
        }
        if ($isReplacingIndex) {
            Write-Output $replaceIndexWith
            $currentIndex = $replaceIndexWith
            $replaceIndexWith++
        } else {
            Write-Output $_
        }
    } else {
        if ($_ -match '-->') {              # Timestamp row
            if ($CheckContent) {
                if ($timestampHasTiming) {
                    Write-Host "Check: Index $currentIndex invalid: time information appears probably twice"
                }
                $timestampHasTiming = $true
            }
            if ($SetTimingFromReferenceFile.Length -gt 0) {
                $referenceTimestamp = $allTimingReferenceFile[$currentIndex]
                if ($referenceTimestamp.Length -gt 0) {
                    Write-Output $referenceTimestamp
                } else {
                    Write-Output $_
                }
            }
            else {
                Write-Output $_
            }
        } else {
            Write-Output $_
        }
    }
}
