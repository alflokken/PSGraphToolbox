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
current signed-in user.
After activation, you may need to reconnect to Microsoft Graph
to obtain a fresh token with updated role claims (wids).

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

# Activates GlobalReader role for 8 hours

### EXAMPLE 2
```
Invoke-GtPimRoleSelfActivation -Role GlobalAdmin -Justification "Emergency admin task" -DurationInHours 2
```

# Activates GlobalAdmin for 2 hours with custom justification

### EXAMPLE 3
```
Invoke-GtPimRoleSelfActivation -RoleDefinitionId "62e90394-69f5-4237-9190-012177145e10"
```

# Activates a role by its definition ID

## PARAMETERS

### -Role
Predefined role to activate.
Valid values: GlobalReader, GlobalAdmin, IntuneAdmin, 
ConditionalAccessAdmin, AuthenticationAdmin.

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
How long the role should remain active.
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

## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Invoke-GtPimRoleSelfActivation.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Invoke-GtPimRoleSelfActivation.md)

