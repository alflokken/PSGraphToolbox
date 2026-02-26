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
Requires UserAuthenticationMethod.ReadWrite.All permission.

## EXAMPLES

### EXAMPLE 1
```
New-GtUserTemporaryAccessPass -inputObject "user@zavainc.com"
```

Issues a 60-minute TAP for the user.

### EXAMPLE 2
```
"user@zavainc.com" | New-GtUserTemporaryAccessPass -LifetimeInMinutes 480 -IsUsableOnce
```

Issues a single-use 8-hour TAP for the user.

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
If true, TAP can only be used once.
Defaults to false.

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

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/New-GtUserTemporaryAccessPass.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/New-GtUserTemporaryAccessPass.md)

