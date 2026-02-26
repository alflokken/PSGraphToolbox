---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserOwnedDevices.md
schema: 2.0.0
---

# Get-GtUserOwnedDevices

## SYNOPSIS
Get devices owned by a user.

## SYNTAX

```
Get-GtUserOwnedDevices [-InputObject] <Object> [<CommonParameters>]
```

## DESCRIPTION
Retrieves devices registered to a user in Entra ID.
Returns comprehensive device details including:
- Device properties (displayName, deviceId, operatingSystem, etc.)
- Enrollment and management status (isManaged, isCompliant, enrollmentType)
- Device registration date and last sign-in timestamp
Results are sorted by approximate last sign-in (most recent first).

Requires scopes: User.Read.All, Device.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtUserOwnedDevices "user@zavainc.com"
```

### EXAMPLE 2
```
"user@zavainc.com" | ownedDevices
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserOwnedDevices.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserOwnedDevices.md)

