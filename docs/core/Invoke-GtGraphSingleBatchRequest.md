---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphSingleBatchRequest.md
schema: 2.0.0
---

# Invoke-GtGraphSingleBatchRequest

## SYNOPSIS
Sends a single $batch request to Microsoft Graph and sorts the responses.

## SYNTAX

```
Invoke-GtGraphSingleBatchRequest [-Requests] <Array> [[-ApiVersion] <String>] [[-PageLimit] <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Internal helper for Invoke-GtGraphBatchRequest.
Posts one batch (max 20 requests) to the $batch endpoint
and returns a hashtable with Successful responses (by request id), Throttled requests (HTTP 429, 502, 503 and 504,
for retry), Failed (id -\> Status, Code, Message, Request) and RetryAfter (highest retry-after value in seconds).
404 emits a warning and the request is left out; any other non-200 status code is recorded in Failed.
Collection responses with @odata.nextLink are completed with Invoke-GtGraphRequest (see -PageLimit);
if that fails, the request is recorded in Failed and its partial data is dropped.
Only a failure of the $batch call itself throws.

## EXAMPLES

### EXAMPLE 1
```
$result = Invoke-GtGraphSingleBatchRequest -Requests @( @{ id = "1"; method = "GET"; url = "users/user1" } )
```

Sends one batch and returns Successful, Throttled, Failed and RetryAfter.

## PARAMETERS

### -Requests
Array of request objects, each with 'id', 'method' and 'url' properties.

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

### -ApiVersion
The Microsoft Graph API version for the batch endpoint (default is v1.0).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: V1.0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageLimit
Maximum number of additional pages to fetch after the first page returned by the batch (default is 100).
0 returns only the first page (a warning is written if more pages exist).
Invoke-GtGraphBatchRequest passes its own -PageLimit minus 1.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphSingleBatchRequest.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphSingleBatchRequest.md)

