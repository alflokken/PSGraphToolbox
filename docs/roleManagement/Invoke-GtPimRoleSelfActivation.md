---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Invoke-GtPimRoleSelfActivation.md
schema: 2.0.0
---

# Invoke-GtPimRoleSelfActivation

## SYNOPSIS
Self-activates a PIM eligible directory role.

## SYNTAX

### ByRoleName
```
Invoke-GtPimRoleSelfActivation [-Role <String>] [-Justification <String>] [-DurationInHours <Int32>]
 [<CommonParameters>]
```

### ByRoleId
```
Invoke-GtPimRoleSelfActivation -RoleDefinitionId <Guid> [-Justification <String>] [-DurationInHours <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Activates a Privileged Identity Management (PIM) eligible role assignment for the 
current signed-in user (resolved via /me, so a delegated sign-in is required).
The activation
is tenant-wide (directory scope '/') and starts immediately.
After activation, you may need to reconnect
to Microsoft Graph to obtain a fresh token with updated role claims (wids); a warning about this is always written.

NOTE: Windows Token Broker caches access tokens persistently.
After PIM activation,
use 'Connect-MgGraph -ContextScope Process' to force a fresh token acquisition with
current role claims.
See: https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference

Requires scopes: RoleAssignmentSchedule.ReadWrite.Directory

## EXAMPLES

### EXAMPLE 1
```
Invoke-GtPimRoleSelfActivation -Role GlobalReader
```

Activates the Global Reader role for 8 hours.

### EXAMPLE 2
```
Invoke-GtPimRoleSelfActivation -Role GlobalAdmin -Justification "Emergency admin task" -DurationInHours 2
```

Activates Global Administrator for 2 hours with a custom justification.

### EXAMPLE 3
```
Invoke-GtPimRoleSelfActivation -RoleDefinitionId "62e90394-69f5-4237-9190-012177145e10"
```

Activates a role by its definition ID.

## PARAMETERS

### -Role
Predefined (commonly used) built-in role to activate.
Valid values: GlobalReader, GlobalAdmin, PrivilegedRoleAdmin, PrivilegedAuthenticationAdmin, AuthenticationAdmin, AuthenticationPolicyAdmin,
ConditionalAccessAdmin, SecurityAdmin, SecurityOperator, SecurityReader, UserAdmin, HelpdeskAdmin, GroupsAdmin, ApplicationAdmin, 'Cloud Application Administrator', HybridIdentityAdmin,
IdentityGovernanceAdmin, IntuneAdmin, ExchangeAdmin, SharePointAdmin, TeamsAdmin, ComplianceAdmin.

Defaults to GlobalReader, so running the function without parameters activates Global Reader.
For any other role, use -RoleDefinitionId.

```yaml
Type: String
Parameter Sets: ByRoleName
Aliases:

Required: False
Position: Named
Default value: GlobalReader
Accept pipeline input: False
Accept wildcard characters: False
```

### -RoleDefinitionId
The GUID of the role definition to activate.
Use this for roles not in the predefined list.

```yaml
Type: Guid
Parameter Sets: ByRoleId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Justification
Business justification for the activation.
Default: "PIM Self Activation"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: PIM Self Activation
Accept pipeline input: False
Accept wildcard characters: False
```

### -DurationInHours
How long the role should remain active, 1-24 hours.
Default: 8 hours.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 8
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### The created roleAssignmentScheduleRequest returned by Graph (hashtable), with dateTime values converted to local time.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Invoke-GtPimRoleSelfActivation.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Invoke-GtPimRoleSelfActivation.md)

