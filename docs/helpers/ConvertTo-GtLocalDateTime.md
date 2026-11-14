---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-GtLocalDateTime.md
schema: 2.0.0
---

# ConvertTo-GtLocalDateTime

## SYNOPSIS
Recursively convert all dateTime values in an object graph from UTC to local time.

## SYNTAX

```
ConvertTo-GtLocalDateTime [[-InputObject] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Walks an object, hashtable/dictionary, or array and converts every \[datetime\] value it
finds - whether a property value, dictionary entry, or collection element - from UTC to
local time, in place.
Recurses into nested objects, dictionaries and arrays at any depth.
Compatible with Windows PowerShell 5.1 and Constrained Language Mode.

Only \[datetime\] values are modified.
Strings, numbers, booleans, GUIDs and the overall
object structure are preserved unchanged.
Conversion is idempotent (a local-time value
passed back in is returned unchanged), so it is safe to call more than once.

A dateTime without a time zone (Kind 'Unspecified') is assumed to be UTC.
This matches Microsoft Graph, which
returns UTC; it would shift values from other sources that are already local (e.g.
\[datetime\]'2024-01-15 12:00').

Used internally by Invoke-GtGraphRequest, Invoke-GtGraphBatchRequest and other functions
that call Invoke-MgGraphRequest directly, to centralize local-time conversion of Microsoft
Graph dateTime values, so consuming functions don't each repeat it.

## EXAMPLES

### EXAMPLE 1
```
$user = Invoke-MgGraphRequest -Uri "v1.0/users/$id" -OutputType PSObject
```

ConvertTo-GtLocalDateTime -InputObject $user
Converts all dateTime properties (including nested ones) on the user object to local time.

### EXAMPLE 2
```
$result = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body
```

ConvertTo-GtLocalDateTime -InputObject $result
Converts dateTime values in a hashtable response (including nested hashtables) to local time.

### EXAMPLE 3
```
$users | ConvertTo-GtLocalDateTime
```

Converts dateTime values for each object piped in.

## PARAMETERS

### -InputObject
The object, hashtable, array, or value to process.
Accepts pipeline input.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### The same object reference with dateTime values converted to local time.
### For a [datetime] input, the converted value is returned (dateTime values are immutable).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-GtLocalDateTime.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-GtLocalDateTime.md)

