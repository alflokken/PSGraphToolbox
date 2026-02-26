---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Revoke-GtUserSession.md
schema: 2.0.0
---

# Revoke-GtUserSession

## SYNOPSIS
Revoke all refresh tokens for a user.

## SYNTAX

```
Revoke-GtUserSession [-InputObject] <Object> [-WhatIf] [-Confirm <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Invalidates all refresh tokens issued to applications for a user.
Also invalidates session cookies in the user's browser.
Requires User.ReadWrite.All or Directory.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
Revoke-GtUserSession -inputObject "user@zavainc.com"
```

### EXAMPLE 2
```
"user@zavainc.com" | Revoke-GtUserSession
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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

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

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Revoke-GtUserSession.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Revoke-GtUserSession.md)

