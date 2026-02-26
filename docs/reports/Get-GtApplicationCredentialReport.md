---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtApplicationCredentialReport.md
schema: 2.0.0
---

# Get-GtApplicationCredentialReport

## SYNOPSIS
Get application registration credentials with expiry information.

## SYNTAX

```
Get-GtApplicationCredentialReport [[-IncludeExpired] <Boolean>] [[-outputType] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves all application registrations with their associated credentials
(client secrets and certificates).
Provides expiry tracking.

Flattens credential arrays to show one row per credential with:
- Application display name and app ID
- Credential type (password/key)
- Key/secret display name
- Start/end dates and days until expiry

For SAML signing certificates on service principals, use Get-GtSamlCertificateReport.

Requires scopes: Application.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtApplicationCredentialReport
```

Generates HTML report of all application credentials.

### EXAMPLE 2
```
Get-GtApplicationCredentialReport -IncludeExpired:$false
```

Shows only active (non-expired) credentials.

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

### Array of credential objects (PSObject mode) or HTML report file path (html mode).
### Each object contains: appDisplayName, appId, credentialType, keyId, credentialDisplayName, startDateTime, endDateTime, daysUntilExpiry, isExpired, appOwners.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtApplicationCredentialReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtApplicationCredentialReport.md)

