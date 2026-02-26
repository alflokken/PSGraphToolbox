---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/isValidGuid.md
schema: 2.0.0
---

# isValidGuid

## SYNOPSIS
Validate if a string is a properly formatted GUID.

## SYNTAX

```
isValidGuid [[-guid] <String>] [<CommonParameters>]
```

## DESCRIPTION
Tests whether a string matches the standard GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).
Pipeline-enabled filter function for validating object IDs.

## EXAMPLES

### EXAMPLE 1
```
"d1d10c1f-4f2e-4f2e-4f2e-4f2e4f2e4f2e" | isValidGuid
```

Returns: $true

### EXAMPLE 2
```
isValidGuid "not-a-guid"
```

Returns: $false

## PARAMETERS

### -guid
The string to validate as a GUID.

```yaml
Type: String
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

### Boolean: $true if valid GUID format, $false otherwise.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/isValidGuid.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/isValidGuid.md)

