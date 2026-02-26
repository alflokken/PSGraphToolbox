---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Sync-GtGraphResourceDelta.md
schema: 2.0.0
---

# Sync-GtGraphResourceDelta

## SYNOPSIS
Synchronize Graph resources using delta queries and persistent state.

## SYNTAX

```
Sync-GtGraphResourceDelta [-ResourcePath] <String> [[-SelectProperties] <String>] [[-Filter] <String>]
 [[-StorageProvider] <String>] [-StoragePath] <String> [-NoWrite] [<CommonParameters>]
```

## DESCRIPTION
Performs incremental synchronization of Microsoft Graph resources using delta queries.
Tracks changes (additions, updates, removals) between sync operations and maintains
state using pluggable storage providers.

First call performs a full sync.
Subsequent calls retrieve only changes since last sync.
Handles delta token expiration (410 Gone) by automatically performing a full resync.

Requires scopes: Varies by resource path (e.g., User.Read.All for users/delta).

## EXAMPLES

### EXAMPLE 1
```
Sync-GtGraphResourceDelta -ResourcePath "users/delta" -SelectProperties "id,displayName,accountEnabled" -StorageProvider JsonFile -StoragePath ".\userState.json"
```

Performs delta sync of users, storing state in JSON file.

### EXAMPLE 2
```
$result = Sync-GtGraphResourceDelta -ResourcePath "users/delta?deltaToken=latest" -SelectProperties "id,displayName" -StoragePath ".\users.json"
```

Start tracking from current state (skip initial full sync).
Useful when you only care about future changes.

### EXAMPLE 3
```
$result = Sync-GtGraphResourceDelta -ResourcePath "groups/delta" -SelectProperties "id,displayName,members" -Filter "id eq 'group-guid-here'" -StoragePath ".\members.json"
```

$result.ChangeLog | Where-Object { $_.description -match 'members_added' }

Changelog format: 'members_removed: id1, id2; members_added: id3, id4'

## PARAMETERS

### -ResourcePath
The Graph API delta resource path (e.g., "users/delta", "groups/delta").

Append "?deltaToken=latest" to skip initial full sync and only track future changes, be aware
that this does not support filter parameters.

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

### -SelectProperties
Comma-separated list of properties to track.
The 'id' property is automatically 
included if not specified.

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

### -Filter
OData $filter expression to apply to the delta query.

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

### -StorageProvider
Storage backend for persisting delta state.
Currently supports: JsonFile.
Future options may include Sql, CosmosDb, etc.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: JsonFile
Accept pipeline input: False
Accept wildcard characters: False
```

### -StoragePath
Path to the storage file (for JsonFile provider).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoWrite
Skip writing updated state to storage.
Useful for testing or dry-run scenarios.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSObject with:
### - ChangeLog: Array of change records (entityId, change type, description)
### - CurrentState: Updated state object containing all entities and deltaLink
### - ItemCount: Total number of entities in current state
## NOTES
For groups, expanding members have known limitations in Graph delta queries.
Initial sync may not return complete member lists due to API behavior. 
Consider using a hybrid approach (regular group members retrieval followed by delta queries) for reliable results.

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Sync-GtGraphResourceDelta.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Sync-GtGraphResourceDelta.md)

