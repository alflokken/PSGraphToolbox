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
Retrieves multiple directory objects by their object IDs using directoryObjects/getByIds.
IDs are sent in chunks of 1000 (API limit), one POST request per chunk.

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

### EXAMPLE 3
```
Get-GtGraphDirectoryObjectsByIds -Type directoryObject -Ids $principalIds | ConvertTo-HashTable
```

Resolves IDs of any object type and builds a lookup hashtable keyed by id.

## PARAMETERS

### -Type
Object types to return.
Accepts multiple values: application, administrativeUnit, appRoleAssignment,
directoryObject, directoryRole, device, group, orgContact, user, servicePrincipal.
Use directoryObject on its own to return objects of any type (no type filter).

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

### Array of directory objects (including @odata.type) matching the specified IDs and types.
### IDs that are not found, or not of the requested type, are omitted. dateTime values are converted to local time.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Get-GtGraphDirectoryObjectsByIds.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Get-GtGraphDirectoryObjectsByIds.md)

