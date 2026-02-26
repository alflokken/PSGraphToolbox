---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphRequest.md
schema: 2.0.0
---

# Invoke-GtGraphRequest

## SYNOPSIS
Wrapper for Invoke-MgGraphRequest with automatic pagination and OData support.

## SYNTAX

```
Invoke-GtGraphRequest [-ResourcePath] <String> [-ApiVersion <String>] [-Filter <String>] [-Search <String>]
 [-Select <String>] [-OrderBy <String>] [-Expand <String>] [-Top <Int32>] [-Count]
 [-AdditionalHeaders <Hashtable>] [-PageLimit <Int32>] [-AccessToken <SecureString>] [<CommonParameters>]
```

## DESCRIPTION
Simplifies Microsoft Graph API calls by handling:
- Automatic pagination (@odata.nextLink processing)
- OData query parameters as native PowerShell parameters
- ConsistencyLevel header for $search and $count queries
- Delta query support with deltaLink tracking
- Automatic Graph connection if not already connected

Requires scopes: Varies by resource path.

## EXAMPLES

### EXAMPLE 1
```
Invoke-GtGraphRequest -ResourcePath "users" -Select "id,displayName"
```

Returns all users with id and displayName.

### EXAMPLE 2
```
Invoke-GtGraphRequest -ResourcePath "users" -Filter "accountEnabled eq true" -Top 10
```

Returns first 10 enabled users.

### EXAMPLE 3
```
Invoke-GtGraphRequest -ResourcePath "users" -Search '"displayName:john"' -Select "id,displayName"
```

Searches users with 'john' in displayName.

### EXAMPLE 4
```
Invoke-GtGraphRequest -ResourcePath "users" -ApiVersion beta -Select "id,signInActivity"
```

Uses beta API to get sign-in activity data.

## PARAMETERS

### -ResourcePath
The Graph API resource path (e.g., "users", "groups/xxx/members").
API version prefix (v1.0/ or beta/) is stripped if included.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiVersion
Graph API version: "v1.0" or "beta".
Defaults to "v1.0".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: V1.0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
OData $filter expression (e.g., "accountEnabled eq true").

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Search
OData $search expression.
Requires quoted strings (e.g., '"displayName:john"').
Automatically adds ConsistencyLevel: eventual header.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Select
Comma-separated list of properties to return.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrderBy
OData $orderby expression (e.g., "displayName desc").

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Expand
OData $expand expression for related entities.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Top
Maximum number of results per page.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Count
Include total count in response.
Adds ConsistencyLevel: eventual header.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalHeaders
Hashtable of additional HTTP headers to include.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageLimit
Maximum number of pages to retrieve.
Defaults to 100.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccessToken
SecureString access token for authentication (optional).

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### For single resources: PSObject with resource properties.
### For collections: Array of PSObjects.
### For delta queries: PSObject with value, deltaLink, and dateRetrieved.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphRequest.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphRequest.md)

