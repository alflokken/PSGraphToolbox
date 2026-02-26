function Invoke-GtGraphBatchRequest {
    <# polly on .net would be nice...
    .SYNOPSIS
    Invokes batch requests to Microsoft Graph with retry logic for throttling.

    .DESCRIPTION
    This function processes an array of Microsoft Graph requests in batches,
    handling throttling by retrying failed requests with respect to the 'retry-after' header.

    .PARAMETER requests
    An array of request objects to be sent in batches, must contain 'id', 'method', and 'url' properties.

    .PARAMETER batchSize
    The number of requests to include in each batch (default is 20).

    .PARAMETER maxRetries
    The maximum number of retry attempts for throttled requests (default is 3).

    .EXAMPLE
    $Requests = @(
        @{ id = "1"; method = "GET"; url = "/users/user1" },
        @{ id = "2"; method = "GET"; url = "/users/user2" }
    )
    $responses = Invoke-GtGraphBatchRequest -requests $Requests

    .EXAMPLE
    # Batch retrieve FIDO2 authentication methods for multiple users
    $batchRequests = @()
    $userIds | ForEach-Object { 
        $batchRequests += @{
            id = $_
            method = "GET"
            url = "users/$_/authentication/fido2Methods"
        }
    }
    $results = Invoke-GtGraphBatchRequest -requests $batchRequests

    This example creates a batch of GET requests to retrieve FIDO2 authentication methods for multiple users.

    .EXAMPLE
    # Batch retrieve service principal display names with select query
    $spnDisplayNames = Invoke-GtGraphBatchRequest -requests ($servicePrincipalIds | ForEach-Object {
        @{
            id = $_
            method = "GET"
            url = "servicePrincipals/$_?`$select=id,displayName"
        }
    })

    This example demonstrates using pipeline notation to create batch requests that retrieve specific properties (id and displayName) from multiple service principals using the $select query parameter.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphBatchRequest.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Requests,
        [int]$BatchSize = 20,
        [int]$MaxRetries = 10
    )

    # init
    $allResponses = @{}
    $pendingRequests = @() + $Requests  # Create copy of requests
    $globalRetryAttempt = 0
    $startTime = Get-Date
    
    Write-Verbose "=== Invoke-GtGraphBatchRequest Started ==="
    Write-Verbose "Total requests: $($Requests.Count)"
    Write-Verbose "Batch size: $BatchSize"
    Write-Verbose "Max retries: $MaxRetries"
    
    # Main processing loop - handles initial requests and retries
    while ( $pendingRequests.Count -gt 0 -and $globalRetryAttempt -le $MaxRetries ) {
        
        $batches = Split-ArrayIntoChunks -Enumerable $pendingRequests -ChunkSize $BatchSize
        $newPendingRequests = @()
        $throttledInThisRound = $false
        $roundStartTime = Get-Date

        Write-Verbose "--- Round $($globalRetryAttempt + 1) Started ---"
        Write-Verbose "Pending requests: $($pendingRequests.Count)"
        Write-Verbose "Batches to process: $($batches.Count)"
        Write-Verbose "Successful so far: $($allResponses.Count)"
        
        # process each batch
        for ( $i = 0; $i -lt $batches.Count; $i++ ) {
            Write-Verbose "Processing batch $($i + 1)/$($batches.Count)"
            $batch = $batches[$i]

            $batchStartTime = Get-Date
            $batchResult = Invoke-GtGraphSingleBatchRequest -requests $batch -Verbose:$false 
            $batchDuration = (Get-Date) - $batchStartTime
            Write-Verbose "Batch $($i + 1) completed in $($batchDuration.TotalSeconds)s - Success: $($batchResult.Successful.Count), Throttled: $($batchResult.Throttled.Count)" 
            
            # Collect successful responses
            $batchResult.Successful.GetEnumerator() | ForEach-Object { $allResponses[$_.Key] = $_.Value}
            
            # Handle throttled requests (add to retry list)
            if ($batchResult.Throttled.Count -gt 0) {
                Write-Verbose "*** THROTTLED *** Retry-after from this batch: $($batchResult.RetryAfter)s"
                $throttledInThisRound = $true
                # Collect throttled requests for next round
                $batchResult.Throttled.GetEnumerator() | ForEach-Object { $newPendingRequests += $_.Value }
            }
            
            # Report progress
            $processedCount = $allResponses.Count
            $remainingCount = $Requests.Count - $processedCount
            if ( $throttledInThisRound -and $batchResult.RetryAfter -gt 0 ) { 
                for ($sleepSec = $batchResult.RetryAfter; $sleepSec -gt 0; $sleepSec--) {
                    Write-Progress -Activity "Processing Graph Requests" -Status "Processed: $processedCount, Remaining: $remainingCount, Batch: $($i + 1)/$($batches.Count), Status: Requests are being throttled- continuing in $sleepSec seconds" -PercentComplete (($processedCount / $Requests.Count) * 100)
                    Start-Sleep -Seconds 1
                }
            }
            else { Write-Progress -Activity "Processing Graph Requests" -Status "Processed: $processedCount, Remaining: $remainingCount, Batch: $($i + 1)/$($batches.Count), Status: Processing" -PercentComplete (($processedCount / $Requests.Count) * 100) }
        }
        
        # Update pending requests for next round
        $pendingRequests = $newPendingRequests
        $roundDuration = (Get-Date) - $roundStartTime
        
        Write-Verbose "--- Round $($globalRetryAttempt + 1) Complete ---"
        Write-Verbose "Round duration: $($roundDuration.TotalSeconds)s"
        Write-Verbose "Total successful: $($allResponses.Count)/$($Requests.Count)"
        Write-Verbose "Pending for retry: $($pendingRequests.Count)"
        
        # If we have pending requests, increment retry counter for next round
        if ($pendingRequests.Count -gt 0) {
            # Only increment global retry counter if we actually got throttled in this round
            if ($throttledInThisRound) {
                $globalRetryAttempt++
                Write-Verbose "*** STARTING RETRY ROUND ***"
                Write-Verbose "Global retry attempt incremented to $globalRetryAttempt/$MaxRetries due to throttled requests"
                Write-Verbose "Will retry $($pendingRequests.Count) throttled requests in next round"
            }
        }
    }
    
    $totalDuration = (Get-Date) - $startTime
    Write-Verbose "=== Invoke-GtGraphBatchRequest Complete ==="
    Write-Verbose "Total duration: $($totalDuration.TotalSeconds)s"
    Write-Verbose "Total successful: $($allResponses.Count)/$($Requests.Count)"
    Write-Verbose "Global retry attempts used: $globalRetryAttempt/$MaxRetries"
    
    if ($pendingRequests.Count -gt 0) {
        Write-Warning "Failed to process $($pendingRequests.Count) requests after $MaxRetries global retry attempts"
        Write-Verbose "Failed requests: $($pendingRequests.Count)"
    }
    
    Write-Progress -Activity "Processing Graph Requests" -Completed
    return $allResponses
}

function Invoke-GtGraphSingleBatchRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Array]$Requests
    )

    $result = @{
        Successful = @{}
        Throttled = @{}
        RetryAfter = 0
    }
    
    $batchBody = @{ requests = $Requests } | ConvertTo-Json -Depth 10
    
    Write-Verbose "Sending batch request with $($Requests.Count) individual requests"
    
    try {
        $batchResponse = Invoke-MgGraphRequest -Method POST -Uri 'v1.0/$batch' -Body $batchBody -OutputType PSObject -Verbose:$false
        Write-Verbose "Batch request completed, processing $($batchResponse.responses.Count) responses"
    }
    catch {
        Write-Verbose "Batch request failed with error: $_"
        Write-Error "Batch request failed: $_"
        throw
    }

    # process individual responses
    foreach ( $response in $batchResponse.responses ) {
        $originalRequest = $Requests | Where-Object { $_.id -eq $response.id }
        # ok
        if ($response.status -eq 200) {
            Write-Verbose "Request $($response.id) succeeded"
            $responseContent = if ($response.body.PSObject.Properties.Name -contains "value") { $response.body.value } else { $response.body }
            $result.Successful[$response.id] = $responseContent
        }
        # throttled - too many request
        elseif ($response.status -eq 429) {
            Write-Verbose "Request $($response.id) throttled (429)"
            $result.Throttled[$response.id] = $originalRequest
            
            # Extract retry-after value if present
            if ($response.headers.'retry-after') {
                try {
                    $retryAfter = [int]$response.headers.'retry-after'
                    if ($retryAfter -gt $result.RetryAfter) { $result.RetryAfter = $retryAfter } # keep max retry-after
                    Write-Verbose "Request $($response.id) retry-after: $retryAfter seconds"
                }
                catch { Write-Verbose "Could not parse retry-after header for request $($response.id): $($response.headers.'retry-after')" }
            }
            else { Write-Verbose "Request $($response.id) throttled but no retry-after header provided" }
        }
        # not found
        elseif ( $response.status -eq 404 ) { write-warning "Request $($response.id) returned 404 Not Found $($response | convertto-json -Compress)" }
        # other errors
        else { throw "Request $($response.id) failed with status $($response.status)" }
    }
    return $result
}