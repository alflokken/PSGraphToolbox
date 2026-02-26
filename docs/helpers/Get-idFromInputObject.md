---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Get-idFromInputObject.md
schema: 2.0.0
---

# Get-idFromInputObject

## SYNOPSIS
Extract identifier from flexible input types.

## SYNTAX

```
Get-idFromInputObject [-InputObject] <Object> [-objectIdOnly] [-AllowRawString] [<CommonParameters>]
```

## DESCRIPTION
Normalizes various input types to an ID and type.
Accepts strings (GUID or UPN),
or objects with 'id' or 'userPrincipalName' properties.

## EXAMPLES

### EXAMPLE 1
```
Get-idFromInputObject "user@zavainc.com"
```

# Returns: @{ id = "user@zavainc.com"; type = "upn" }

### EXAMPLE 2
```
$user | Get-idFromInputObject -objectIdOnly
```

# Extracts object ID, throws if not a valid GUID.

## PARAMETERS

### -InputObject
String (GUID/UPN) or object with id/userPrincipalName property.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -objectIdOnly
Require the result to be a valid GUID.
Throws if input is UPN or string.

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

### -AllowRawString
Allow non-GUID, non-UPN strings (e.g., displayName).
Returns type as "string".

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

### PSObject with 'id' (the extracted identifier) and 'type' (guid, upn, or string).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Get-idFromInputObject.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Get-idFromInputObject.md)

