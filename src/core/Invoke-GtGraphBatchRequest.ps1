function Invoke-GtGraphBatchRequest {
    <#
    .SYNOPSIS
    Invokes batch requests to Microsoft Graph with retry logic for throttling.

    .DESCRIPTION
    This function processes an array of Microsoft Graph requests in batches,
    handling throttling by retrying failed requests with respect to the 'retry-after' header.

    Response handling per request:
    - 200: the response is added to the result (dateTime values converted to local time).
    - 429, 502, 503, 504 (throttled or temporarily unavailable): retried in a later round, after waiting for the highest
      retry-after value of the round, or an exponential backoff (2^round seconds, max 60, plus jitter) when none was given.
    - 404: a warning is written and the request is left out of the result.
    - Any other status code (including 201 and 204) is a failure, so in practice the function is meant for GET requests.

    Failures (non-retryable status codes, a failed @odata.nextLink page, and requests still throttled after -MaxRetries
    rounds) do not abort the batch. The request is left out of the result and one non-terminating error is written per
    failed request, after all retries are done. The ErrorRecord's TargetObject is the original request (use .id),
    and its FullyQualifiedErrorId is 'GraphBatch.<status>.<graph error code>'. Use -ErrorAction SilentlyContinue with
    -ErrorVariable to handle failures yourself, or -ErrorAction Stop to fail fast.

    Collection responses with @odata.nextLink are paged: the remaining pages are fetched with Invoke-GtGraphRequest
    (one request at a time, outside the batch), up to -PageLimit pages per request.

    Requires scopes: Varies by request.

    .PARAMETER Requests
    An array of request objects to be sent in batches. Each must contain 'id' (unique), 'method' and 'url'
    (relative to the API version, without a leading slash, e.g. "users/{id}"). An optional 'headers' hashtable is
    sent with the request and reused when following nextLinks.

    .PARAMETER BatchSize
    The number of requests to include in each batch (default is 20, the Graph maximum).

    .PARAMETER MaxRetries
    The maximum number of retry rounds for throttled requests (default is 10).

    .PARAMETER ApiVersion
    The Microsoft Graph API version for the batch endpoint, e.g. v1.0 or beta (default is v1.0).

    .PARAMETER PageLimit
    Maximum number of pages per request, including the first page returned by the batch (default is 100, range 1-9999).
    Use 1 to return only the first page. A warning is written when a result is truncated.

    .OUTPUTS
    Hashtable keyed by request id. Each value is the response body's 'value' collection (all retrieved pages combined)
    or, for single resources, the response body itself. Requests that returned 404 or failed are missing; failures are
    reported as non-terminating errors (see DESCRIPTION).

    .EXAMPLE
    $Requests = @(
        @{ id = "1"; method = "GET"; url = "users/user1@contoso.com" },
        @{ id = "2"; method = "GET"; url = "users/user2@contoso.com" }
    )
    $responses = Invoke-GtGraphBatchRequest -Requests $Requests
    Retrieves two users in one batch; $responses["1"] and $responses["2"] hold the user objects.

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

    .EXAMPLE
    $requests = @( @{ id = "users"; method = "GET"; url = "users?`$select=id&`$top=999" } )
    $results = Invoke-GtGraphBatchRequest -Requests $requests -PageLimit 5
    Returns up to 5 pages of users for request id 'users'. A warning is written if more pages exist.

    .EXAMPLE
    $results = Invoke-GtGraphBatchRequest -Requests $requests -ErrorAction SilentlyContinue -ErrorVariable batchErrors
    $failed = $batchErrors | Where-Object { $_.FullyQualifiedErrorId -like 'GraphBatch.*' }
    $failed.TargetObject.id
    Returns the successful responses and collects failed requests (e.g. 403, or throttled after all retries) in $batchErrors.
    The filter is needed because -ErrorVariable also holds errors caught inside nested calls (e.g. while paging).

    .NOTES
    Pages after the first are fetched one request at a time (not batched). If a later page fails, that request is reported as failed and left out.
    Delta queries (@odata.deltaLink) are not supported in batch requests; use Sync-GtGraphResourceDelta or Invoke-GtGraphRequest.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphBatchRequest.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Requests,
        [int]$BatchSize = 20,
        [int]$MaxRetries = 10,
        [string]$ApiVersion = 'v1.0',
        [ValidateRange(1, 9999)]
        [int]$PageLimit = 100
    )
    # polly on .net would be nice...

    # init
    $allResponses = @{}
    $allFailed = @{}
    $pendingRequests = @() + $Requests  # Create copy of requests
    $globalRetryAttempt = 0
    $startTime = Get-Date
    
    Write-GtVerbose "=== Invoke-GtGraphBatchRequest Started ==="
    Write-GtVerbose "Total requests: $($Requests.Count)"
    Write-GtVerbose "Batch size: $BatchSize"
    Write-GtVerbose "Max retries: $MaxRetries"
    
    # Main processing loop - handles initial requests and retries
    while ( $pendingRequests.Count -gt 0 -and $globalRetryAttempt -le $MaxRetries ) {
        
        $batches = Split-ArrayIntoChunks -Enumerable $pendingRequests -ChunkSize $BatchSize
        $newPendingRequests = @()
        $throttledInThisRound = $false
        $roundRetryAfter = 0
        $roundStartTime = Get-Date

        Write-GtVerbose "--- Round $($globalRetryAttempt + 1) Started ---"
        Write-GtVerbose "Pending requests: $($pendingRequests.Count)"
        Write-GtVerbose "Batches to process: $($batches.Count)"
        Write-GtVerbose "Successful so far: $($allResponses.Count)"
        
        # process each batch
        for ( $i = 0; $i -lt $batches.Count; $i++ ) {
            Write-GtVerbose "Processing batch $($i + 1)/$($batches.Count)"
            $batch = $batches[$i]

            $batchStartTime = Get-Date
            $batchResult = Invoke-GtGraphSingleBatchRequest -requests $batch -ApiVersion $ApiVersion -Verbose:$false -PageLimit ($PageLimit - 1) # first page has already been served
            $batchDuration = (Get-Date) - $batchStartTime
            Write-GtVerbose "Batch $($i + 1) completed in $($batchDuration.TotalSeconds)s - Success: $($batchResult.Successful.Count), Throttled: $($batchResult.Throttled.Count), Failed: $($batchResult.Failed.Count)" 
            
            # Collect successful and failed responses
            $batchResult.Successful.GetEnumerator() | ForEach-Object { $allResponses[$_.Key] = $_.Value}
            $batchResult.Failed.GetEnumerator() | ForEach-Object { $allFailed[$_.Key] = $_.Value }
            
            # Handle throttled requests (add to retry list)
            if ($batchResult.Throttled.Count -gt 0) {
                Write-GtVerbose "*** THROTTLED *** Retry-after from this batch: $($batchResult.RetryAfter)s"
                $throttledInThisRound = $true
                if ( $batchResult.RetryAfter -gt $roundRetryAfter ) { $roundRetryAfter = $batchResult.RetryAfter }
                # Collect throttled requests for next round
                $batchResult.Throttled.GetEnumerator() | ForEach-Object { $newPendingRequests += $_.Value }
            }
            
            # Report progress
            $processedCount = $allResponses.Count + $allFailed.Count
            $remainingCount = $Requests.Count - $processedCount
            Write-Progress -Activity "Processing Graph Requests" -Status "Processed: $processedCount, Remaining: $remainingCount, Batch: $($i + 1)/$($batches.Count), Status: Processing" -PercentComplete (($processedCount / $Requests.Count) * 100)
        }
        
        # Update pending requests for next round
        $pendingRequests = $newPendingRequests
        $roundDuration = (Get-Date) - $roundStartTime
        
        Write-GtVerbose "--- Round $($globalRetryAttempt + 1) Complete ---"
        Write-GtVerbose "Round duration: $($roundDuration.TotalSeconds)s"
        Write-GtVerbose "Total successful: $($allResponses.Count)/$($Requests.Count)"
        Write-GtVerbose "Pending for retry: $($pendingRequests.Count)"
        
        # If we have pending requests, increment retry counter for next round
        if ($pendingRequests.Count -gt 0) {
            # Only increment global retry counter if we actually got throttled in this round
            if ($throttledInThisRound) {
                $globalRetryAttempt++
                Write-GtVerbose "*** STARTING RETRY ROUND ***"
                Write-GtVerbose "Global retry attempt incremented to $globalRetryAttempt/$MaxRetries due to throttled requests"
                Write-GtVerbose "Will retry $($pendingRequests.Count) throttled requests in next round"

                # wait only when another round will run; exponential backoff (with jitter) when no retry-after was given
                if ( $globalRetryAttempt -le $MaxRetries ) {
                    # honour retry-after when Graph sent one, else back off 2, 4, 8 ... seconds (max 60)
                    $backoffSeconds = [Math]::Min([Math]::Pow(2, $globalRetryAttempt), 60)
                    $waitSeconds = if ( $roundRetryAfter -gt 0 ) { $roundRetryAfter } else { $backoffSeconds }
                    for ( $sleepSec = $waitSeconds; $sleepSec -gt 0; $sleepSec-- ) {
                        Write-Progress -Activity "Processing Graph Requests" -Status "Processed: $($allResponses.Count + $allFailed.Count), Remaining: $($pendingRequests.Count), Retry round: $globalRetryAttempt/$MaxRetries, Status: Requests are being throttled - continuing in $sleepSec seconds" -PercentComplete ((($allResponses.Count + $allFailed.Count) / $Requests.Count) * 100)
                        Start-Sleep -Seconds 1
                    }
                }
            }
        }
    }
    
    $totalDuration = (Get-Date) - $startTime
    Write-GtVerbose "=== Invoke-GtGraphBatchRequest Complete ==="
    Write-GtVerbose "Total duration: $($totalDuration.TotalSeconds)s"
    Write-GtVerbose "Total successful: $($allResponses.Count)/$($Requests.Count)"
    Write-GtVerbose "Global retry attempts used: $globalRetryAttempt/$MaxRetries"

    # requests still throttled after the last round are failures too
    foreach ( $request in $pendingRequests ) {
        $allFailed[[string]$request.id] = @{ Status = 429; Code = 'ThrottledRetriesExhausted'; Message = "Still throttled or unavailable after $MaxRetries retry rounds."; Request = $request }
    }

    # non-terminating errors, emitted last so retries and paging are complete; callers choose via -ErrorAction / -ErrorVariable
    foreach ( $failure in $allFailed.Values ) {
        Write-Error -Message "Graph batch request '$($failure.Request.id)' failed with status $($failure.Status): $($failure.Code) $($failure.Message)" -TargetObject $failure.Request -ErrorId "GraphBatch.$($failure.Status).$($failure.Code)"
    }
    Write-Progress -Activity "Processing Graph Requests" -Completed
    return $allResponses
}

function Invoke-GtGraphSingleBatchRequest {
    <#
    .SYNOPSIS
    Sends a single $batch request to Microsoft Graph and sorts the responses.

    .DESCRIPTION
    Internal helper for Invoke-GtGraphBatchRequest. Posts one batch (max 20 requests) to the $batch endpoint
    and returns a hashtable with Successful responses (by request id), Throttled requests (HTTP 429, 502, 503 and 504,
    for retry), Failed (id -> Status, Code, Message, Request) and RetryAfter (highest retry-after value in seconds).
    404 emits a warning and the request is left out; any other non-200 status code is recorded in Failed.
    Collection responses with @odata.nextLink are completed with Invoke-GtGraphRequest (see -PageLimit);
    if that fails, the request is recorded in Failed and its partial data is dropped.
    Only a failure of the $batch call itself throws.

    .PARAMETER Requests
    Array of request objects, each with 'id', 'method' and 'url' properties.

    .PARAMETER ApiVersion
    The Microsoft Graph API version for the batch endpoint (default is v1.0).

    .PARAMETER PageLimit
    Maximum number of additional pages to fetch after the first page returned by the batch (default is 100).
    0 returns only the first page (a warning is written if more pages exist).
    Invoke-GtGraphBatchRequest passes its own -PageLimit minus 1.

    .EXAMPLE
    $result = Invoke-GtGraphSingleBatchRequest -Requests @( @{ id = "1"; method = "GET"; url = "users/user1" } )
    Sends one batch and returns Successful, Throttled, Failed and RetryAfter.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphSingleBatchRequest.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Array]$Requests,
        [string]$ApiVersion = 'v1.0',
        [int]$PageLimit = 100
    )

    $result = @{
        Successful = @{}
        Throttled = @{}
        Failed = @{}
        RetryAfter = 0
    }
    $retryableStatusCodes = 429, 502, 503, 504
    
    $batchBody = @{ requests = $Requests } | ConvertTo-Json -Depth 10
    
    Write-GtVerbose "Sending batch request with $($Requests.Count) individual requests"
    
    try {
        $batchResponse = Invoke-MgGraphRequest -Method POST -Uri "$ApiVersion/`$batch" -Body $batchBody -OutputType PSObject -Verbose:$false
        Write-GtVerbose "Batch request completed, processing $($batchResponse.responses.Count) responses"
    }
    catch {
        Write-GtVerbose "Batch request failed with error: $_"
        Write-Error "Batch request failed: $_"
        throw
    }

    # process individual responses
    foreach ( $response in $batchResponse.responses ) {
        $originalRequest = $Requests | Where-Object { $_.id -eq $response.id }
        # ok
        if ($response.status -eq 200) {
            Write-GtVerbose "Request $($response.id) succeeded"
            $responseContent = if ($response.body.PSObject.Properties.Name -contains "value") { $response.body.value } else { $response.body }
            # convert dateTime values (UTC -> local) in place; discarding output preserves the response shape
            $null = ConvertTo-GtLocalDateTime -InputObject $responseContent

            # follow @odata.nextLinks
            $nextLink = $response.body.'@odata.nextLink'
            if ( $nextLink -and $PageLimit -gt 0 ) {
                Write-GtVerbose "Request $($response.id) has more pages, following @odata.nextLink"
                try { $remainingPages = Invoke-GtGraphRequest -ResourcePath $nextLink -AdditionalHeaders $originalRequest.headers -PageLimit $PageLimit -Verbose:$false }
                catch {
                    # partial data is dropped so a truncated result is never mistaken for a complete one
                    $result.Failed[$response.id] = @{ Status = 'NextLink'; Code = 'PageRetrievalFailed'; Message = "Failed to retrieve remaining pages: $_"; Request = $originalRequest }
                    continue
                }
                $responseContent = @($responseContent) + @($remainingPages)
                Write-GtVerbose "Request $($response.id): $(@($responseContent).Count) items after paging"
            }
            elseif ( $nextLink ) { Write-Warning "Request $($response.id): pageLimit $PageLimit reached. Result truncated." }

            $result.Successful[$response.id] = $responseContent
        }
        # throttled or transiently unavailable - retry
        elseif ($response.status -in $retryableStatusCodes) {
            Write-GtVerbose "Request $($response.id) retryable status $($response.status)"
            $result.Throttled[$response.id] = $originalRequest
            
            # Extract retry-after value if present
            if ($response.headers.'retry-after') {
                try {
                    $retryAfter = [int]$response.headers.'retry-after'
                    if ($retryAfter -gt $result.RetryAfter) { $result.RetryAfter = $retryAfter } # keep max retry-after
                    Write-GtVerbose "Request $($response.id) retry-after: $retryAfter seconds"
                }
                catch { Write-GtVerbose "Could not parse retry-after header for request $($response.id): $($response.headers.'retry-after')" }
            }
            else { Write-GtVerbose "Request $($response.id) status $($response.status) but no retry-after header provided" }
        }
        # not found
        elseif ( $response.status -eq 404 ) { write-warning "Request $($response.id) returned 404 Not Found $($response | convertto-json -Compress -d 10)" }
        # other errors - recorded so the remaining responses are kept
        else {
            Write-GtVerbose "Request $($response.id) failed with status $($response.status)"
            $result.Failed[$response.id] = @{ Status = $response.status; Code = $response.body.error.code; Message = $response.body.error.message; Request = $originalRequest }
        }
    }
    return $result
}