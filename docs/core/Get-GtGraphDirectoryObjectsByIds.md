---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Get-GtGraphDirectoryObjectsByIds.md
schema: 2.0.0
---

# Get-GtGraphDirectoryObjectsByIds

## SYNOPSIS
Bulk lookup of directory objects by ID.

## SYNTAX

```
Get-GtGraphDirectoryObjectsByIds [-Type] <Array> [-Ids] <Array> [<CommonParameters>]
```

## DESCRIPTION
Retrieves multiple directory objects (users, groups, devices) by their object IDs
in a single API call.
Automatically chunks requests into batches of 1000 (API limit).

More efficient than individual lookups when resolving many IDs.

Requires scopes: Directory.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtGraphDirectoryObjectsByIds -Type user -Ids @("guid1", "guid2")
```

Returns user objects for the specified IDs.

### EXAMPLE 2
```
Get-GtGraphDirectoryObjectsByIds -Type user,group -Ids $mixedIds
```

Returns users and groups matching any of the specified IDs.

## PARAMETERS

### -Type
Object types to return: user, group, device.
Accepts multiple values.

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

### -Ids
Array of object IDs (GUIDs) to look up.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Array of directory objects matching the specified IDs and types.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Get-GtGraphDirectoryObjectsByIds.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Get-GtGraphDirectoryObjectsByIds.md)

