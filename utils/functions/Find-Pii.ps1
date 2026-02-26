# pre-push hook
function Find-Pii {
    # .SYNOPSIS
    #     Scans files for potential Personally Identifiable Information (PII) based on predefined patterns.
    [cmdletbinding()]
    param (
        $Path = $PSScriptRoot,
        [string[]]$Include = @("*.ps1", "*.psm1", "*.md"),
        [string[]]$Exclude = @("pii-patterns.txt"),
        $PiiPatternsPath = ".\pii-patterns.txt",
        [switch]$ThrowOnMatch
    )

    $Exclude += ($PiiPatternsPath -split "\\")[-1]

    if (-not (Test-Path $PiiPatternsPath)) { throw "pii-patterns.txt not found" }
    else {
        $patterns = Get-Content $PiiPatternsPath
        if ( $patterns.Count -eq 0 ) { throw "pii-patterns.txt is empty" }
    }

    $results = Get-ChildItem -Path $Path -Recurse -File -Include $Include -Exclude $Exclude | Select-String -Pattern $patterns 

    if ( $results.Count -gt 0 ) {
        if ( $ThrowOnMatch ) { throw "Push aborted due to potential PII findings. Skip the pre-push hook with --no-verify if you are sure." }
        else {
            Write-Host "Potential PII found in the following files:" -ForegroundColor Red
            return $results
        }
    } else { Write-Host "3.15 - PII not found." -ForegroundColor Green }
}