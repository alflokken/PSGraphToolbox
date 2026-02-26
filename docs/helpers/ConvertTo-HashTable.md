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
Faster alternative to Group-Object -AsHashTable (~50x faster for large datasets).
Creates a hashtable where each key is the value of the specified property.

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
Array of objects to convert.
Accepts pipeline input.

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
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-HashTable.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-HashTable.md)

