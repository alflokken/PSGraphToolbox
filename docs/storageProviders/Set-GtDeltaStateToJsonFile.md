---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Set-GtDeltaStateToJsonFile.md

Write delta state to JSON file.
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
Writes delta query state to a JSON file with UTF-8 encoding.
Used by Sync-GtGraphResourceDelta to persist state between runs.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Set-GtDeltaStateToJsonFile.md

Write delta state to JSON file.](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Set-GtDeltaStateToJsonFile.md

Write delta state to JSON file.)

