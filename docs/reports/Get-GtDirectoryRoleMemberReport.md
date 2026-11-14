---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRoleMemberReport.md
schema: 2.0.0
---

# Get-GtDirectoryRoleMemberReport

## SYNOPSIS
Get all Entra ID directory role assignments and eligibilities with resolved names.

## SYNTAX

```
Get-GtDirectoryRoleMemberReport [-IncludePimActivations] [-SkipGroupExpansion] [[-OutputType] <Object>]
 [<CommonParameters>]
```

## DESCRIPTION
Retrieves both active role assignments and PIM eligible roles from Entra ID.
Resolves principal displayNames (users, groups, service principals) and role names.
Group assignments are expanded into the group's direct members (not nested groups), and the group entries are removed from the output.
Use -SkipGroupExpansion to keep the group entries as they are instead.
Optionally includes PIM activation data from audit logs.

state is one of:
- active: activated through PIM (startDateTime/endDateTime from the activation)
- active (permanent): active assignment without a current PIM activation
- eligible: time-bound eligibility
- eligible (permanent): eligibility without an end date

PIM activation data is retrieved from the directory audit logs (category: RoleManagement,
activityDisplayName: Add member to role completed (PIM activation)).
Microsoft retains
these logs for 30 days by default, so activation history is limited to that window.

Requires scopes: RoleManagement.Read.Directory, Directory.Read.All.
Optional: AuditLog.Read.All (-IncludePimActivations).

## EXAMPLES

### EXAMPLE 1
```
Get-GtDirectoryRoleMemberReport
```

Returns all role members with enriched data as HTML report, without PIM activation data.

### EXAMPLE 2
```
Get-GtDirectoryRoleMemberReport -OutputType PSObject
```

Returns role assignments as PSObject array without PIM activation data.

### EXAMPLE 3
```
Get-GtDirectoryRoleMemberReport -IncludePimActivations -OutputType PSObject | Where-Object { $_.state -like "eligible*" -and $_.recentPimActivations -eq 0 }
```

Returns eligible role members that have not activated their role in the last 30 days.

### EXAMPLE 4
```
Get-GtDirectoryRoleMemberReport -SkipGroupExpansion -OutputType PSObject | Where-Object { $_.memberType -eq "group" }
```

Returns the groups that hold a directory role, without expanding them into their members.

## PARAMETERS

### -IncludePimActivations
Adds recentPimActivations (number of PIM activations in the last 30 days) to eligible entries.
Switch parameter, off by default;
without it the property is omitted.

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

### -SkipGroupExpansion
Keeps group assignments as group entries (memberType 'group') instead of expanding them into their members.
Switch parameter, off by default.
No group membership requests are made.
For group entries recentPimActivations is empty, as activations are logged for the activating user, not the group.

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

### -OutputType
Output format: PSObject or html.
Defaults to html.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Html
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSObject mode: array of role member objects with principalId, roleDefinitionId, roleDisplayName, directoryScopeId ('/' for tenant-wide, otherwise e.g. an administrative unit; in html mode only shown when some assignment is scoped), principalDisplayName,
### memberType (user, servicePrincipal, group, ... or 'user (via group: <group name>)'), userPrincipalName, startDateTime, endDateTime,
### state and, with -IncludePimActivations, recentPimActivations. With -SkipGroupExpansion, group assignments are returned as memberType 'group'.
### html mode: nothing is returned. Entries (without principalId and roleDefinitionId) are grouped by role and written to
### .\PSGraphToolbox_DirectoryRoles_<yyyyMMdd_HHmmss>.html in the current directory, which is opened in the default browser.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRoleMemberReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRoleMemberReport.md)

