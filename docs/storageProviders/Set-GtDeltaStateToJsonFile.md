---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Set-GtDeltaStateToJsonFile.md
schema: 2.0.0
---

# Set-GtDeltaStateToJsonFile

## SYNOPSIS
Save delta state to a JSON file.

## SYNTAX

```
Set-GtDeltaStateToJsonFile [[-Path] <String>] [[-state] <Object>]
```

## DESCRIPTION
Writes delta query state to a JSON file (UTF-8, compressed, depth 10), overwriting any existing file.
Used by Sync-GtGraphResourceDelta to persist state between runs.

## EXAMPLES

### EXAMPLE 1
```
Set-GtDeltaStateToJsonFile -Path "C:\state\users-delta.json" -State $state
```

Saves the delta state to the file, overwriting any existing content.

## PARAMETERS

### -Path
File path where the delta state will be saved.

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

### -state
PSObject containing the delta state to save.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Set-GtDeltaStateToJsonFile.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Set-GtDeltaStateToJsonFile.md)

