# stuff to process
$objects = 0..100 

# Thread-safe collections
$results = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()
$errors = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$objects | ForEach-Object -ThrottleLimit 20 -Parallel {

    $object = $_
    $results = $using:results
    $errors = $using:errors
    Import-Module "C:\users\alf\iam\PSGraphToolbox\PsGraphToolbox.psm1" -ErrorAction Stop
    
    try {
        get-object -objectId $object | ForEach-Object { $results.Add($_) }
    }
    catch {
        $errors.Add([PSCustomObject]@{
            objectId = $object
            ErrorMessage = $_.Exception.Message
        })
    }
}

# Convert to arrays for easier handling
[array]$resultArray = $results
[array]$errorArray = $errors

Write-Host "Completed in $($stopwatch.Elapsed.TotalSeconds)s | Objects: $($objects.Count) | Results: $($resultArray.Count) | Errors: $($errorArray.Count)" -ForegroundColor Green