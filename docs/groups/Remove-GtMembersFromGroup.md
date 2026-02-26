---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Remove-GtMembersFromGroup.md
schema: 2.0.0
---

# Remove-GtMembersFromGroup

## SYNOPSIS
Remove members from a group.

## SYNTAX

```
Remove-GtMembersFromGroup [-Group] <Object> [-Members] <Object> [-WhatIf] [[-Confirm] <Boolean>]
 [<CommonParameters>]
```

## DESCRIPTION
Removes one or more members from an Entra ID group.

Requires scopes: GroupMember.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
Remove-GtMembersFromGroup -group "Sales Team" -members @("user1@zavainc.com")
```

## PARAMETERS

### -Group
Group object, displayName, or object ID.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: id, groupId

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Members
Array of member objects, UPNs, or object IDs to remove.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: memberIds

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Preview changes without making them.

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

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Summary object with removedCount and timestamp properties.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Remove-GtMembersFromGroup.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Remove-GtMembersFromGroup.md)

