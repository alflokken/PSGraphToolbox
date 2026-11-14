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
Retrieves SAML/SSO signing certificates from enterprise applications (service principals with
preferredSingleSignOnMode 'saml').
These are certificates used for SAML token signing, separate from app registration credentials.
Certificates are de-duplicated by customKeyIdentifier (thumbprint), so each certificate appears once.
Expired certificates are included.
Results are sorted by daysUntilExpiry (expired and soonest-expiring first).

For application registration credentials (secrets/certificates), use Get-GtAppCredentialReport.

Requires scopes: Application.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtSamlCertificateReport
```

Generates HTML report of all SAML signing certificates.

### EXAMPLE 2
```
Get-GtSamlCertificateReport -outputType PSObject | Where-Object { $_.daysUntilExpiry -lt 30 }
```

Returns SAML certificates that expire within 30 days (or have expired).

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

### PSObject mode: array of certificate objects with appDisplayName, appId, keyId, certificateName, startDateTime, endDateTime,
### daysUntilExpiry, isExpired, appOwners.
### html mode: nothing is returned. The report is written to .\PSGraphToolbox_SamlCertificates_<yyyyMMdd_HHmmss>.html
### in the current directory and opened in the default browser.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtSamlCertificateReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtSamlCertificateReport.md)

