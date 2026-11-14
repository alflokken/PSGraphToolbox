---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtAppPermissionsReport.md
schema: 2.0.0
---

# Get-GtAppPermissionsReport

## SYNOPSIS
Reports service principal permissions and flags privileged ones.

## SYNTAX

```
Get-GtAppPermissionsReport [-Raw] [-IncludeOwners] [-IncludeSignInActivity] [-IncludeAppOwnerOrganization]
 [[-AdditionalServicePrincipalV1SelectProperties] <String>] [<CommonParameters>]
```

## DESCRIPTION
Lists service principals with app role assignments, delegated grants or directory roles, as an HTML report or raw objects.
Service principals without any of these are left out.

Privilege classification:
- Application permissions and delegated scopes are flagged isPrivileged when listed as High in the Zero Trust Assessment
  consent grant permission table, or when they belong to a High permission family (e.g.
Mail.*, Files.*).
  *.Selected and *.ReadBasic* permissions are never flagged.
- Directory roles use the role definition's isPrivileged flag.
Delegated grants are expanded to one entry per scope; principalDisplayName is resolved for user consent grants only.

The HTML report is written to the current directory as PSGraphToolbox_PrivilegedAppPermissionsReport_{timestamp}.html
and opened in the default browser, with all 'id' and '*Id' properties omitted.

Requires scopes: Application.Read.All, DelegatedPermissionGrant.Read.All, RoleManagement.Read.Directory, Directory.Read.All.
Optional: AuditLog.Read.All (-IncludeSignInActivity), CrossTenantInformation.ReadBasic.All (-IncludeAppOwnerOrganization).

## EXAMPLES

### EXAMPLE 1
```
Get-GtAppPermissionsReport
```

Generates an HTML report of service principal permissions.

### EXAMPLE 2
```
Get-GtAppPermissionsReport -Raw -IncludeOwners | Where-Object { $_.displayName -like "*Backup*" }
```

Returns raw objects including owners and filters them in the pipeline.

### EXAMPLE 3
```
Get-GtAppPermissionsReport -IncludeSignInActivity -AdditionalServicePrincipalV1SelectProperties "appRoleAssignmentRequired,signInAudience"
```

Generates a report with sign-in activity and extra service principal properties.

## PARAMETERS

### -Raw
Return enriched objects with all collected properties and IDs retained, without generating HTML.

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

### -IncludeOwners
Include owners of the service principals (servicePrincipalOwners) and their applications (applicationRegistrationOwners).
The properties are only added when owners exist.

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

### -IncludeSignInActivity
Include service principal sign-in activity (beta endpoint) as signInActivity, with the last sign-in timestamp per activity type
(lastSignIn, delegatedClientSignInActivity, delegatedResourceSignInActivity, applicationAuthenticationClientSignInActivity,
applicationAuthenticationResourceSignInActivity).

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

### -IncludeAppOwnerOrganization
Include the owner organization (tenant) of each application as appOwnerOrganization: "Name \[defaultDomainName\]",
or the tenant ID if it cannot be resolved.

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

### -AdditionalServicePrincipalV1SelectProperties
Additional comma-separated servicePrincipal properties to select (v1.0, no spaces), e.g.
appRoleAssignmentRequired,signInAudience.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### -Raw: array of service principal objects with id, appId, displayName, accountEnabled, appOwnerOrganizationId, servicePrincipalType,
### any additional properties, and:
### - appRoleAssignments (appRoleId, resourceId, resourceDisplayName, principalType, permissionName, isPrivileged)
### - oauth2PermissionGrants (one entry per scope: consentType, principalId, principalDisplayName, resourceId, resourceDisplayName, scope, isPrivileged)
### - assignedRoles (id, displayName, isPrivileged)
### - hasPrivilegedApplicationPermissions, hasPrivilegedDelegatedPermissions, hasPrivilegedRoleAssignments, hasRoleAssignments
### - optional: appOwnerOrganization, servicePrincipalOwners, applicationRegistrationOwners, signInActivity
### Default: nothing is returned; the HTML report is written (see description).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtAppPermissionsReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtAppPermissionsReport.md)

