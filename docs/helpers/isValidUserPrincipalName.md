---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/isValidUserPrincipalName.md
schema: 2.0.0
---

# isValidUserPrincipalName

## SYNOPSIS
Validate if a string is a properly formatted UserPrincipalName (UPN).

## SYNTAX

```
isValidUserPrincipalName [[-userPrincipalName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Tests whether a string matches a valid email/UPN format (user@domain.com).
Pipeline-enabled filter function for validating user principal names.

## EXAMPLES

### EXAMPLE 1
```
"user@zavainc.com" | isValidUserPrincipalName
```

Returns: $true

### EXAMPLE 2
```
isValidUserPrincipalName "invalid-upn"
```

Returns: $false

## PARAMETERS

### -userPrincipalName
The string to validate as a UPN.

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

### Boolean: $true if valid UPN format, $false otherwise.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/isValidUserPrincipalName.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/isValidUserPrincipalName.md)

