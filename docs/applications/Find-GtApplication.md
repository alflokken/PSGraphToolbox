---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/applications/Find-GtApplication.md
schema: 2.0.0
---

# Find-GtApplication

## SYNOPSIS
Search Entra ID application registrations by displayName, id or appId.

## SYNTAX

```
Find-GtApplication [-SearchString] <String> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
\[AI-GENERATED\] This function was generated using Claude Opus 4.8.

Finds application registrations by displayName, or by exact object id / appId (GUID), and returns one object per match with:
- Basic properties (sign-in audience, publisher, identifier URIs, notes, tags, created date)
- Owners of the application registration
- Requested API permissions (requiredResourceAccess), resolved to Resource:Permission (delegated and application)
- Permissions the app exposes itself (published delegated scopes, app roles, pre-authorized app count)
- Credentials: secrets, certificates (with expiry, sorted by end date) and federated identity credentials, plus a credentialStatus summary
- Sign-in configuration (redirect URIs, implicit grant, fallback public client, token encryption, group and optional claims)

credentialStatus covers secrets and certificates only: none, ok, expiring (within 30 days) or expired (any credential past its end date).
Federated credentials do not expire and are listed separately.
Secret hints and values are never returned.

This describes the application's design-time configuration.
Tenant usage (assignments, consented permissions, owners of the enterprise app)
belongs to the service principal - see Find-GtServicePrincipal.
For tenant-wide credential expiry use Get-GtAppCredentialReport.

Lookups are scoped to the matched applications only, using batched requests.
Permission names are resolved only for the resource APIs the matches actually request permissions from;
permissions of resource APIs that cannot be resolved are shown by ID.
Queries the beta endpoint.

Requires scopes: Application.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Find-GtApplication "contoso"
```

Returns application registrations with a word in displayName starting with 'contoso'.

### EXAMPLE 2
```
Find-GtApplication "00000000-0000-0000-0000-000000000000"
```

Returns the application registration with the given appId (or object id).

### EXAMPLE 3
```
Find-GtApplication "contoso" | Select-Object displayName, owners, apiPermissionsApplication
```

Shows owners and requested application permissions for matching app registrations.

### EXAMPLE 4
```
Find-GtApplication "contoso" | Select-Object displayName, credentialStatus, secrets
```

Shows credential status and secret expiry for matching app registrations.

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
Extra application properties to include in results (comma separated, no spaces, e.g.
serviceManagementReference,disabledByMicrosoftStatus).

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### One PSObject per application with:
### id, displayName, appId, signInAudience, createdDateTime, publisherDomain, verifiedPublisher (display name), identifierUris, notes, tags,
### any -AdditionalProperties,
### owners (UPN or displayName),
### credentialStatus (none, ok, expiring, expired),
### secrets (displayName, keyId, startDateTime, endDateTime, expired), certificates (same plus type and usage),
### federatedCredentials (name, issuer, subject, audiences),
### apiPermissionsDelegated, apiPermissionsApplication (Resource:Permission),
### publishedDelegatedScopes, publishedAppRoles, preAuthorizedAppCount,
### webRedirectUris, spaRedirectUris, publicClientRedirectUris, implicitIdToken, implicitAccessToken, isFallbackPublicClient,
### tokenEncryption (true if a token encryption key is set), groupMembershipClaims, optionalClaims (true if optional claims are configured).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/applications/Find-GtApplication.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/applications/Find-GtApplication.md)

