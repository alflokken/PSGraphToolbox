---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroup.md
schema: 2.0.0
---

# Get-GtGroup

## SYNOPSIS
Get a group from Entra ID by object ID, displayName, or group object.

## SYNTAX

```
Get-GtGroup [-InputObject] <Object> [[-AdditionalProperties] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a single Microsoft Entra ID group by object ID, displayName, or group object.
Accepts pipeline input.
Returns group properties (id, displayName, description, createdDateTime, groupTypes, mailEnabled, securityEnabled) by default.
Additional properties can be requested via -AdditionalProperties.
Throws if the group is not found.

Requires scopes: Group.Read.All

## EXAMPLES

### EXAMPLE 1
```
Get-GtGroup "Sales Team"
```

Returns the group with displayName 'Sales Team'.

### EXAMPLE 2
```
"00000000-0000-0000-0000-000000000000" | Get-GtGroup
```

Returns the group with the specified object ID.

### EXAMPLE 3
```
Get-GtGroup $groupObj -AdditionalProperties "membershipRule"
```

Returns the group with additional property 'membershipRule'.

## PARAMETERS

### -InputObject
Group object, displayName, or object ID.
Accepts pipeline input.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: id

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AdditionalProperties
Comma-separated list of additional properties to include in the response (e.g., "membershipRule,assignedLabels").

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
If displayName is not unique, returns the first match.
Throws if no group is found.
Additional properties must be valid Graph API group properties.

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroup.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroup.md)

