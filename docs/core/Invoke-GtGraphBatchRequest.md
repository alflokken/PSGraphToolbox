---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphBatchRequest.md
schema: 2.0.0
---

# Invoke-GtGraphBatchRequest

## SYNOPSIS
Invokes batch requests to Microsoft Graph with retry logic for throttling.

## SYNTAX

```
Invoke-GtGraphBatchRequest [-Requests] <Array> [[-BatchSize] <Int32>] [[-MaxRetries] <Int32>]
 [[-ApiVersion] <String>] [[-PageLimit] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
This function processes an array of Microsoft Graph requests in batches,
handling throttling by retrying failed requests with respect to the 'retry-after' header.

Response handling per request:
- 200: the response is added to the result (dateTime values converted to local time).
- 429, 502, 503, 504 (throttled or temporarily unavailable): retried in a later round, after waiting for the highest
  retry-after value of the round, or an exponential backoff (2^round seconds, max 60, plus jitter) when none was given.
- 404: a warning is written and the request is left out of the result.
- Any other status code (including 201 and 204) is a failure, so in practice the function is meant for GET requests.

Failures (non-retryable status codes, a failed @odata.nextLink page, and requests still throttled after -MaxRetries
rounds) do not abort the batch.
The request is left out of the result and one non-terminating error is written per
failed request, after all retries are done.
The ErrorRecord's TargetObject is the original request (use .id),
and its FullyQualifiedErrorId is 'GraphBatch.\<status\>.\<graph error code\>'.
Use -ErrorAction SilentlyContinue with
-ErrorVariable to handle failures yourself, or -ErrorAction Stop to fail fast.

Collection responses with @odata.nextLink are paged: the remaining pages are fetched with Invoke-GtGraphRequest
(one request at a time, outside the batch), up to -PageLimit pages per request.

Requires scopes: Varies by request.

## EXAMPLES

### EXAMPLE 1
```
$Requests = @(
```

@{ id = "1"; method = "GET"; url = "users/user1@contoso.com" },
    @{ id = "2"; method = "GET"; url = "users/user2@contoso.com" }
)
$responses = Invoke-GtGraphBatchRequest -Requests $Requests
Retrieves two users in one batch; $responses\["1"\] and $responses\["2"\] hold the user objects.

### EXAMPLE 2
```
# Batch retrieve FIDO2 authentication methods for multiple users
```

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

### EXAMPLE 3
```
# Batch retrieve service principal display names with select query
```

$spnDisplayNames = Invoke-GtGraphBatchRequest -requests ($servicePrincipalIds | ForEach-Object {
    @{
        id = $_
        method = "GET"
        url = "servicePrincipals/$_?\`$select=id,displayName"
    }
})

This example demonstrates using pipeline notation to create batch requests that retrieve specific properties (id and displayName) from multiple service principals using the $select query parameter.

### EXAMPLE 4
```
$requests = @( @{ id = "users"; method = "GET"; url = "users?`$select=id&`$top=999" } )
```

$results = Invoke-GtGraphBatchRequest -Requests $requests -PageLimit 5
Returns up to 5 pages of users for request id 'users'.
A warning is written if more pages exist.

### EXAMPLE 5
```
$results = Invoke-GtGraphBatchRequest -Requests $requests -ErrorAction SilentlyContinue -ErrorVariable batchErrors
```

$failed = $batchErrors | Where-Object { $_.FullyQualifiedErrorId -like 'GraphBatch.*' }
$failed.TargetObject.id
Returns the successful responses and collects failed requests (e.g.
403, or throttled after all retries) in $batchErrors.
The filter is needed because -ErrorVariable also holds errors caught inside nested calls (e.g.
while paging).

## PARAMETERS

### -Requests
An array of request objects to be sent in batches.
Each must contain 'id' (unique), 'method' and 'url'
(relative to the API version, without a leading slash, e.g.
"users/{id}").
An optional 'headers' hashtable is
sent with the request and reused when following nextLinks.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BatchSize
The number of requests to include in each batch (default is 20, the Graph maximum).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 20
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxRetries
The maximum number of retry rounds for throttled requests (default is 10).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiVersion
The Microsoft Graph API version for the batch endpoint, e.g.
v1.0 or beta (default is v1.0).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: V1.0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageLimit
Maximum number of pages per request, including the first page returned by the batch (default is 100, range 1-9999).
Use 1 to return only the first page.
A warning is written when a result is truncated.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Hashtable keyed by request id. Each value is the response body's 'value' collection (all retrieved pages combined)
### or, for single resources, the response body itself. Requests that returned 404 or failed are missing; failures are
### reported as non-terminating errors (see DESCRIPTION).
## NOTES
Pages after the first are fetched one request at a time (not batched).
If a later page fails, that request is reported as failed and left out.
Delta queries (@odata.deltaLink) are not supported in batch requests; use Sync-GtGraphResourceDelta or Invoke-GtGraphRequest.

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphBatchRequest.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphBatchRequest.md)

