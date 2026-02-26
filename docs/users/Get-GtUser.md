---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUser.md
schema: 2.0.0
---

# Get-GtUser

## SYNOPSIS
Get a user by ID or UPN.

## SYNTAX

```
Get-GtUser [-InputObject] <Object> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a single user from Entra ID by object ID or UPN.

Requires scopes: User.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtUser "user@zavainc.com"
```

### EXAMPLE 2
```
"user@zavainc.com" | Get-GtUser
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

### -AdditionalProperties
Extra properties to include in results.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUser.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUser.md)

