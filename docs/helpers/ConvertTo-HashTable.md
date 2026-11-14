---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-HashTable.md
schema: 2.0.0
---

# ConvertTo-HashTable

## SYNOPSIS
Convert array of objects to hashtable keyed by a property.

## SYNTAX

```
ConvertTo-HashTable [-inputObject] <Object[]> [[-keyProperty] <String>] [<CommonParameters>]
```

## DESCRIPTION
Creates a 1:1 lookup hashtable where each key is the value of the specified property and the value is a single object.
Use only when keyProperty is unique (e.g.
id, appId).

NOT a drop-in replacement for Group-Object -AsHashTable: duplicate keys are silently overwritten (last object wins).
For 1:many relations (e.g.
role assignments by principalId), use Group-Object -Property \<name\> -AsHashTable -AsString.
Much faster than Group-Object -AsHashTable (~50x for large datasets) when keys are unique.

## EXAMPLES

### EXAMPLE 1
```
$users | ConvertTo-HashTable -keyProperty "id"
```

Creates hashtable where $ht\["user-guid"\] returns the user object.

### EXAMPLE 2
```
$apps | ConvertTo-HashTable -keyProperty "appId"
```

Creates hashtable keyed by appId.

## PARAMETERS

### -inputObject
Array of objects (or hashtables) to convert.
Accepts pipeline input.
Null or empty input returns an empty hashtable; items that are themselves $null are skipped.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -keyProperty
Property name to use as hashtable key.
Defaults to "id".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Id
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Hashtable with keyProperty values as keys and full objects as values.
### Throws if a non-null item has a missing or null keyProperty value. Duplicate keys: the last object wins.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-HashTable.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-HashTable.md)

