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
or objects with 'id' or 'userPrincipalName' properties (id is used when both exist).

The value is classified as 'guid', 'upn' (see isValidUserPrincipalName) or, with -AllowRawString, 'string'.
Throws for null/empty input, objects without id/userPrincipalName, and values that are neither a GUID nor
a recognized UPN (e.g.
guest #EXT# UPNs or display names) unless -AllowRawString is used.

## EXAMPLES

### EXAMPLE 1
```
Get-idFromInputObject "user@zavainc.com"
```

Returns an object with id 'user@zavainc.com' and type 'upn'.

### EXAMPLE 2
```
$user | Get-idFromInputObject -objectIdOnly
```

Returns the object ID of the piped user; throws if it is not a valid GUID.

### EXAMPLE 3
```
Get-idFromInputObject "Sales Team" -AllowRawString
```

Returns an object with id 'Sales Team' and type 'string'.

## PARAMETERS

### -InputObject
String (GUID/UPN) or object with id/userPrincipalName property.
Accepts pipeline input.

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
Throws if the value is a UPN or any other string.

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

