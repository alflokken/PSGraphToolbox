---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroupMembers.md
schema: 2.0.0
---

# Get-GtGroupMembers

## SYNOPSIS
Get members of a group.

## SYNTAX

```
Get-GtGroupMembers [-InputObject] <Object> [-Transitive] [<CommonParameters>]
```

## DESCRIPTION
Retrieves direct members of an Entra ID group, or with -Transitive all members of nested groups as well.
Members can be users, groups, devices or service principals; properties that do not apply to a member type are empty.

Requires scopes: GroupMember.Read.All or Group.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtGroupMembers -InputObject "Sales Team"
```

Returns the direct members of the group 'Sales Team'.

### EXAMPLE 2
```
"00000000-0000-0000-0000-000000000000" | Get-GtGroupMembers -Transitive
```

Returns all members of the group, including members of nested groups.

## PARAMETERS

### -InputObject
Group object, displayName, or object ID.
Accepts pipeline input.
A displayName must match exactly one group.

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

### -Transitive
Get transitive members (nested group expansion).
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Array of member objects with @odata.type, id, accountEnabled, userPrincipalName, displayName.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroupMembers.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroupMembers.md)

