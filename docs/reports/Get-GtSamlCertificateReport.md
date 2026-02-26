---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtSamlCertificateReport.md
schema: 2.0.0
---

# Get-GtSamlCertificateReport

## SYNOPSIS
Get SAML signing certificates from service principals with expiry information.

## SYNTAX

```
Get-GtSamlCertificateReport [[-outputType] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves SAML/SSO signing certificates from enterprise applications (service principals).
These are certificates used for SAML token signing, separate from app registration credentials.

For application registration credentials (secrets/certificates), use Get-GtApplicationCredentialReport.

Requires scopes: Application.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtSamlCertificateReport
```

Generates HTML report of all SAML signing certificates.

## PARAMETERS

### -outputType
Output format: PSObject or html.
Defaults to html.

```yaml
Type: String
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

### Array of certificate objects (PSObject mode) or HTML report file path (html mode).
### Each object contains: appDisplayName, appId, keyId, certificateName, startDateTime, endDateTime, daysUntilExpiry, isExpired, appOwners.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtSamlCertificateReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtSamlCertificateReport.md)

