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
Revocation can take a few minutes,
and does not apply to external (guest) users, who sign in through their home tenant.
Unless -WhatIf is used or -Confirm is $false, you are prompted to confirm (Y/N).

Requires scopes: User.RevokeSessions.All (least privileged), or User.ReadWrite.All / Directory.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
Revoke-GtUserSession -inputObject "user@zavainc.com"
```

Revokes all sessions for the user after confirmation.

### EXAMPLE 2
```
"user@zavainc.com" | Revoke-GtUserSession -WhatIf
```

Shows which user's sessions would be revoked, without making changes.

### EXAMPLE 3
```
Revoke-GtUserSession -inputObject "user@zavainc.com" -Confirm $false
```

Revokes all sessions without prompting.

## PARAMETERS

### -InputObject
User object, UPN, or object ID.
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

### -WhatIf
Preview the action without making changes.

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
Prompt for confirmation.
Defaults to true.
Set to $false to skip the prompt.

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

### PSObject with userId, success (value returned by Graph) and timestamp. Nothing is returned with -WhatIf or when cancelled.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Revoke-GtUserSession.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Revoke-GtUserSession.md)

