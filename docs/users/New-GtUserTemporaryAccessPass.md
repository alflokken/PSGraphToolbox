---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/New-GtUserTemporaryAccessPass.md
schema: 2.0.0
---

# New-GtUserTemporaryAccessPass

## SYNOPSIS
Issue a new Temporary Access Pass (TAP) for a user.

## SYNTAX

```
New-GtUserTemporaryAccessPass [-InputObject] <Object> [-LifetimeInMinutes <Int32>] [-IsUsableOnce] [-WhatIf]
 [-Confirm <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Creates a new Temporary Access Pass for a user via MS Graph API.
Unless -WhatIf is used or -Confirm is $false, you are prompted to confirm (Y/N).
The tenant's Temporary Access Pass policy must allow the requested lifetime and usage.

Requires scopes: UserAuthenticationMethod.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
New-GtUserTemporaryAccessPass -inputObject "user@zavainc.com"
```

Issues a 60-minute TAP for the user after confirmation.

### EXAMPLE 2
```
"user@zavainc.com" | New-GtUserTemporaryAccessPass -LifetimeInMinutes 480 -IsUsableOnce
```

Issues a single-use 8-hour TAP for the user.

### EXAMPLE 3
```
New-GtUserTemporaryAccessPass "user@zavainc.com" -Confirm $false
```

Issues a TAP without prompting (for automation).

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

### -LifetimeInMinutes
TAP validity duration in minutes (10-43200).
Defaults to 60.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 60
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsUsableOnce
If specified, the TAP can only be used once.
By default the TAP is multi-use.

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

### PSObject with userId, temporaryAccessPass (the pass in clear text), lifetimeInMinutes, isUsableOnce,
### startDateTime (local time) and methodUsabilityReason. Nothing is returned with -WhatIf or when cancelled.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/New-GtUserTemporaryAccessPass.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/New-GtUserTemporaryAccessPass.md)

