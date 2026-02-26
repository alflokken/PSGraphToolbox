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
Retrieves members of an Entra ID group.
Supports transitive membership lookup.

Requires scopes: GroupMember.Read.All or Group.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtGroupMembers -InputObject "Sales Team"
```

### EXAMPLE 2
```
"00000000-0000-0000-0000-000000000000" | Get-GtGroupMembers -Transitive
```

## PARAMETERS

### -InputObject
Group object, displayName, or object ID.

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

### Array of member objects with id, accountEnabled, userPrincipalName, displayName.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroupMembers.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroupMembers.md)

