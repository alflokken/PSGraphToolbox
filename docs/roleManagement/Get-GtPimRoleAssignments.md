---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Get-GtPimRoleAssignments.md
schema: 2.0.0
---

# Get-GtPimRoleAssignments

## SYNOPSIS
Gets PIM role assignments (active and/or eligible) for a user.

## SYNTAX

```
Get-GtPimRoleAssignments [[-Principal] <Object>] [[-State] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves Privileged Identity Management (PIM) directory role assignments
for the specified user or the current signed-in user.
Can retrieve active
assignments, eligible assignments, or both.

Only roles assigned directly to the user are returned (roles received through group membership are not included).
Requires an existing Microsoft Graph connection (Connect-MgGraph); throws if not connected.

Requires scopes: RoleEligibilitySchedule.Read.Directory, RoleAssignmentSchedule.Read.Directory, User.Read.All

## EXAMPLES

### EXAMPLE 1
```
Get-GtPimRoleAssignments
```

Returns all role assignments (active and eligible) for the current user.

### EXAMPLE 2
```
Get-GtPimRoleAssignments -State Eligible
```

Returns only eligible roles for the current user.

### EXAMPLE 3
```
Get-GtPimRoleAssignments -Principal "admin@zavainc.com" -State Active
```

Returns only active roles for a specific user.

### EXAMPLE 4
```
$user | Get-GtPimRoleAssignments
```

Returns the role assignments of the piped user objects.

## PARAMETERS

### -Principal
The user to retrieve roles for.
Accepts a user object, GUID, or userPrincipalName, also from the pipeline.
If not specified, retrieves roles for the signed-in account of the current Graph context
(delegated sign-in only; app-only connections have no account).

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -State
Filter by assignment state.
Valid values: All, Active, Eligible.
Default: All (returns both active and eligible assignments).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Array of role assignment objects with properties: principalId, userPrincipalName, roleDisplayName, roleId,
### state (eligible or active), scheduleEnd (end date/time, or 'NoExpiration'), Status,
### MemberType (assignmentType for active roles, e.g. Assigned or Activated; memberType for eligible roles, e.g. Direct).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Get-GtPimRoleAssignments.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Get-GtPimRoleAssignments.md)

