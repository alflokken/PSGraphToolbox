---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtAppCredentialReport.md
schema: 2.0.0
---

# Get-GtAppCredentialReport

## SYNOPSIS
Get application registration credentials with expiry information.

## SYNTAX

```
Get-GtAppCredentialReport [[-IncludeExpired] <Boolean>] [[-outputType] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves all application registrations with their associated credentials
(client secrets and certificates).
Provides expiry tracking.

Flattens credential arrays to show one row per credential with:
- Application display name and app ID
- Credential type ("Password (Client Secret)" or "Key (Certificate)")
- Key/secret display name
- Start/end dates and days until expiry
- Application owners (display names, '; '-separated)
Results are sorted by daysUntilExpiry (expired and soonest-expiring first).

For SAML signing certificates on service principals, use Get-GtSamlCertificateReport.
Federated identity credentials (workload identity federation) are not included.

Requires scopes: Application.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtAppCredentialReport
```

Generates HTML report of all application credentials.

### EXAMPLE 2
```
Get-GtAppCredentialReport -IncludeExpired:$false -outputType PSObject
```

Returns only active (non-expired) credentials as objects.

## PARAMETERS

### -IncludeExpired
Include expired credentials in the report.
Defaults to $true.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -outputType
Output format: PSObject or html.
Defaults to html.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Html
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSObject mode: array of credential objects with appDisplayName, appId, credentialType, keyId, credentialDisplayName,
### startDateTime, endDateTime, daysUntilExpiry, isExpired, appOwners.
### html mode: nothing is returned. The report is written to .\PSGraphToolbox_ApplicationCredentials_<yyyyMMdd_HHmmss>.html
### in the current directory and opened in the default browser.
## NOTES
Renamed from Get-GtApplicationCredentialReport in v2.0.0.

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtAppCredentialReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtAppCredentialReport.md)

