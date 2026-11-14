---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Test-GtDeltaStateJsonFile.md
schema: 2.0.0
---

# Test-GtDeltaStateJsonFile

## SYNOPSIS
Check if a delta state JSON file exists.

## SYNTAX

```
Test-GtDeltaStateJsonFile [[-Path] <String>]
```

## DESCRIPTION
Tests whether a delta state file exists at the specified path.
Throws if the parent directory does not exist, or if the path has no directory part (e.g.
'state.json'; use '.\state.json').
Used by Sync-GtGraphResourceDelta to validate the storage path before syncing.

## EXAMPLES

### EXAMPLE 1
```
Test-GtDeltaStateJsonFile -Path "C:\state\users-delta.json"
```

Returns $true if the state file exists.
Throws if the parent directory does not exist.

## PARAMETERS

### -Path
File path to check.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### Boolean: $true if file exists, $false otherwise.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Test-GtDeltaStateJsonFile.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Test-GtDeltaStateJsonFile.md)

