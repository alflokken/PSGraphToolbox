---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/New-GtRequestUri.md
schema: 2.0.0
---

# New-GtRequestUri

## SYNOPSIS
Construct a Graph API URI with OData query parameters.

## SYNTAX

```
New-GtRequestUri [-resourcePath] <String> [[-filter] <String>] [[-select] <String>] [[-search] <String>]
 [[-orderBy] <String>] [[-expand] <String>] [[-top] <Int32>] [-count] [[-apiVersion] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Builds a properly formatted and escaped Graph API URI from individual OData parameters.
Used internally by Invoke-GtGraphRequest.

## EXAMPLES

### EXAMPLE 1
```
New-GtRequestUri -resourcePath "users" -filter "accountEnabled eq true" -select "id,displayName"
```

Constructs a Graph API URI with filter and select parameters.
Returns: v1.0/users?$filter=accountEnabled%20eq%20true&$select=id,displayName

### EXAMPLE 2
```
New-GtRequestUri -resourcePath "groups" -apiVersion "beta" -top 10 -count -select "id,displayName,membershipRule"
```

Constructs a beta API URI for groups with top, count, and select parameters.
Returns: beta/groups?$select=id,displayName,membershipRule&$top=10&$count=true

## PARAMETERS

### -resourcePath
The Graph API resource path (version prefix stripped if included).

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

### -filter
OData $filter expression.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -select
Comma-separated list of properties.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -search
OData $search expression.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -orderBy
OData $orderby expression.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -expand
OData $expand expression.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -top
Maximum results per page.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -count
Include $count=true in query.

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

### -apiVersion
API version: "v1.0" or "beta".
Defaults to "v1.0".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: V1.0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### String containing the constructed URI.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/New-GtRequestUri.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/New-GtRequestUri.md)

