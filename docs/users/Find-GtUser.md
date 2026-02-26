---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Find-GtUser.md
schema: 2.0.0
---

# Find-GtUser

## SYNOPSIS
Search Entra ID users by displayName or UPN.

## SYNTAX

```
Find-GtUser [-SearchString] <String> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
Finds users by partial displayName or exact UPN.
Returns basic properties.
Supports extra properties via -AdditionalProperties.
Requires User.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Find-GtUser "john"
```

Searches for users with 'john' in displayName.

### EXAMPLE 2
```
Find-GtUser "john.doe@zavainc.com"
```

Returns exact match for UPN.

## PARAMETERS

### -SearchString
Search string (min 3 chars).
Partial match for displayName, exact for UPN.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
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

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Find-GtUser.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Find-GtUser.md)

