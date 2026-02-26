---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserAuthenticationMethods.md
schema: 2.0.0
---

# Get-GtUserAuthenticationMethods

## SYNOPSIS
Get authentication methods for a user.

## SYNTAX

```
Get-GtUserAuthenticationMethods [-InputObject] <Object> [[-MethodType] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves registered authentication methods for a user.
Supports filtering by method type (fido2, authenticator, etc.).

Requires scopes: UserAuthenticationMethod.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtUserAuthenticationMethods "user@zavainc.com"
```

### EXAMPLE 2
```
"user@zavainc.com" | authMethods -methodType fido2Methods
```

## PARAMETERS

### -InputObject
User object, UPN, or object ID.

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

### -MethodType
Filter by method type.
Defaults to 'methods' (all).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Methods
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Object containing array of authentication methods for the user.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserAuthenticationMethods.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserAuthenticationMethods.md)

