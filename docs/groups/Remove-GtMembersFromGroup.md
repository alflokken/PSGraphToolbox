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
Group and Members must be object IDs (GUIDs) or objects with an id property (for example, output from Find-GtGroup or Get-GtUser).
Display names and UPNs are not accepted; look up the object first.
Members that are not in the group are skipped with a warning.
Unless -WhatIf is used or -Confirm is set to $false, you are prompted to confirm (Y/N) before anything is removed.
Members are removed one at a time (one DELETE request per member).
Writes a summary message to the host.

Only direct user members can be removed: the membership check reads the group's user members, so groups, devices and service principals are treated as not in the group and skipped.

Requires scopes: GroupMember.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
Remove-GtMembersFromGroup -group "00000000-0000-0000-0000-000000000000" -members @("11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222")
```

Removes two users, identified by object ID, from the group after confirmation.

### EXAMPLE 2
```
$group = Find-GtGroup "Sales Team" | Select-Object -First 1
```

$user = Get-GtUser "user1@zavainc.com"
Remove-GtMembersFromGroup -group $group -members $user -WhatIf
Shows what would be removed using group and user objects (their id property is used) without making changes.

### EXAMPLE 3
```
Remove-GtMembersFromGroup -group "00000000-0000-0000-0000-000000000000" -members "11111111-1111-1111-1111-111111111111" -Confirm:$false
```

Removes a user from the group without prompting for confirmation.

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
Array of member objects (any objects with an id property) or member object IDs (GUIDs) to remove.
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
Prompt for confirmation (Y/N).
Defaults to $true.
Set to $false to skip the prompt.

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

### None. Progress and results are written to the host.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Remove-GtMembersFromGroup.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Remove-GtMembersFromGroup.md)

