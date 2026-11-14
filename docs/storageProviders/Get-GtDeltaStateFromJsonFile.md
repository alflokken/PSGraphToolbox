---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Get-GtDeltaStateFromJsonFile.md
schema: 2.0.0
---

# Get-GtDeltaStateFromJsonFile

## SYNOPSIS
Retrieve delta state from a JSON file.

## SYNTAX

```
Get-GtDeltaStateFromJsonFile [[-Path] <String>]
```

## DESCRIPTION
Reads delta query state from a JSON file.
Returns $null if the file doesn't exist.
Used by Sync-GtGraphResourceDelta to persist state between runs.

## EXAMPLES

### EXAMPLE 1
```
Get-GtDeltaStateFromJsonFile -Path "C:\state\users-delta.json"
```

Returns the stored delta state, or $null on the first run.

## PARAMETERS

### -Path
File path where the delta state is stored.

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

### PSObject containing the delta state, or $null if file doesn't exist.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Get-GtDeltaStateFromJsonFile.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Get-GtDeltaStateFromJsonFile.md)

