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
Adds one or more members to a Microsoft Entra ID group.
Group and Members must be object IDs (GUIDs) or objects with an id property (for example, output from Find-GtGroup or Get-GtUser).
Display names and UPNs are not accepted; look up the object first.
Removes duplicate member IDs and, unless -skipMembershipCheck is used, skips members that are already direct user members of the group.
Members are added in chunks of 20 per PATCH request (members@odata.bind).
Writes a summary message to the host and supports -WhatIf for dry-run preview.
Throws on errors and warns for non-fatal issues (e.g., already a member).

The membership check only covers user members: adding a group, device or service principal that is already a member makes the request fail.

Requires scopes: GroupMember.ReadWrite.All

## EXAMPLES

### EXAMPLE 1
```
Add-GtMembersToGroup -Group "00000000-0000-0000-0000-000000000000" -Members @("11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222")
```

Adds two users, identified by object ID, to the group.
Members already in the group are skipped.

### EXAMPLE 2
```
$group = Find-GtGroup "Sales Team" | Select-Object -First 1
```

$user = Get-GtUser "user1@zavainc.com"
Add-GtMembersToGroup -Group $group -Members $user -WhatIf
Shows what would be added using group and user objects (their id property is used) without making changes.

### EXAMPLE 3
```
Add-GtMembersToGroup -Group "00000000-0000-0000-0000-000000000000" -Members "11111111-1111-1111-1111-111111111111" -skipMembershipCheck
```

Attempts to add a user to a group without checking if they are already a member.

## PARAMETERS

### -Group
Group object (any object with an id property) or group object ID (GUID).
Aliases: id, groupId.

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
Array of member objects (any objects with an id property) or member object IDs (GUIDs) to add.
Alias: memberIds.

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
The request fails if any member is already present.

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
Preview changes without making them (input validation and the membership check still run).

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

### None. Progress and results are written to the host.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Add-GtMembersToGroup.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Add-GtMembersToGroup.md)

