---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/servicePrincipals/Find-GtServicePrincipal.md
schema: 2.0.0
---

# Find-GtServicePrincipal

## SYNOPSIS
Search Entra ID service principals (enterprise apps) by displayName, id or appId.

## SYNTAX

```
Find-GtServicePrincipal [-SearchString] <String> [-AdditionalProperties <String>] [-IncludeSignInActivity]
 [<CommonParameters>]
```

## DESCRIPTION
\[AI-GENERATED\] This function was generated using Claude Opus 4.8.

Finds service principals by displayName, or by exact object id / appId (GUID), and returns one object per match with:
- Basic properties (type, enabled, assignment required, home tenant, verified publisher, SSO mode, tags, notes)
- Owners
- Users and groups assigned to the enterprise app (appRoleAssignedTo), as display names
- Granted application permissions (appRoleAssignments) and delegated permissions (oauth2PermissionGrants, admin and user consent combined), as Resource:Permission

Lookups are scoped to the matched service principals only, using batched requests.
Permission names are resolved only for the resource APIs actually referenced by the matches.
For app registration design (redirect URIs, credentials, exposed scopes) see Find-GtApplication.
Queries the beta endpoint.

Requires scopes: Application.Read.All, AppRoleAssignment.ReadWrite.All or Directory.Read.All (assignments), DelegatedPermissionGrant.Read.All (delegated grants).
Optional: AuditLog.Read.All (-IncludeSignInActivity).

## EXAMPLES

### EXAMPLE 1
```
Find-GtServicePrincipal "contoso"
```

Returns service principals with a word in displayName starting with 'contoso'.

### EXAMPLE 2
```
Find-GtServicePrincipal "00000003-0000-0000-c000-000000000000"
```

Returns the service principal with the given appId (or object id).

### EXAMPLE 3
```
Find-GtServicePrincipal "contoso" | Select-Object displayName, assignedUsers, assignedGroups
```

Shows who has been assigned to matching enterprise apps.

### EXAMPLE 4
```
Find-GtServicePrincipal "contoso" -IncludeSignInActivity | Select-Object displayName, @{ n = 'lastSignIn'; e = { $_.signInActivity.lastSignIn } }
```

Shows when matching enterprise apps last signed in.

## PARAMETERS

### -SearchString
Search string (3-99 chars).
A GUID is matched exactly against id or appId; any other string is a displayName
search that matches words starting with the string (e.g.
'contoso' matches 'Contoso HR App').

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalProperties
Extra service principal properties to include in results (comma separated, no spaces, e.g.
signInAudience,loginUrl).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeSignInActivity
Adds a signInActivity property with the last sign-in timestamp per activity type (lastSignIn, delegatedClientSignInActivity,
delegatedResourceSignInActivity, applicationAuthenticationClientSignInActivity, applicationAuthenticationResourceSignInActivity).
Queried per matched appId (batched, beta endpoint).
Values are null when no sign-in has been recorded.

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

### One PSObject per service principal with:
### id, displayName, appId, createdDateTime, servicePrincipalType, accountEnabled, appRoleAssignmentRequired, appOwnerOrganizationId,
### verifiedPublisher (display name), preferredSingleSignOnMode, tags, notes, any -AdditionalProperties,
### owners (UPN or displayName), assignedUsers, assignedGroups (display names),
### apiPermissionsApplication, apiPermissionsDelegated (Resource:Permission, resource names without spaces)
### and, with -IncludeSignInActivity, signInActivity.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/servicePrincipals/Find-GtServicePrincipal.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/servicePrincipals/Find-GtServicePrincipal.md)

