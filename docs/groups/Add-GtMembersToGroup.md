---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Add-GtMembersToGroup.md
schema: 2.0.0
---

# Add-GtMembersToGroup

## SYNOPSIS
Adds one or more members to an Entra ID (Azure AD) group with batching, duplicate, and membership checks.

## SYNTAX

```
Add-GtMembersToGroup [-Group] <Object> [-Members] <Object> [-skipMembershipCheck] [-WhatIf]
 [<CommonParameters>]
```

## DESCRIPTION
Adds one or more users to a Microsoft Entra ID group.
Accepts group and member input as objects, display names, UPNs, or object IDs.
Handles batching (20 per request), removes duplicate members, and skips users already in the group (unless -skipMembershipCheck is used).
Provides summary output and supports -WhatIf for dry-run preview.
Throws on errors and warns for non-fatal issues (e.g., already a member).

Requires scopes: GroupMember.ReadWrite.All

## EXAMPLES

### EXAMPLE 1
```
Add-GtMembersToGroup -Group "Sales Team" -Members @("user1@zavainc.com", "user2@zavainc.com")
```

Adds two users to the "Sales Team" group, skipping any already present.

### EXAMPLE 2
```
Add-GtMembersToGroup -Group $groupObj -Members $userList -WhatIf
```

Shows what would be added without making changes.

### EXAMPLE 3
```
Add-GtMembersToGroup -Group "00000000-0000-0000-0000-000000000000" -Members "user@zavainc.com" -skipMembershipCheck
```

Attempts to add a user to a group without checking if they are already a member.

## PARAMETERS

### -Group
Group object, displayName, or object ID.
Accepts pipeline input.

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
Array of member objects, UPNs, or object IDs to add.
Accepts pipeline input.

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

### -skipMembershipCheck
If specified, skips checking for existing group membership.
May cause errors if some members are already present.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Summary object with addedCount, skippedCount, and errorCount properties.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Add-GtMembersToGroup.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Add-GtMembersToGroup.md)

