---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantInfo.md
schema: 2.0.0
---

# Get-GtTenantInfo

## SYNOPSIS
Get tenant organization information.

## SYNTAX

```
Get-GtTenantInfo [<CommonParameters>]
```

## DESCRIPTION
Retrieves basic tenant information including display name, tenant ID, tenant type,
domain configuration, and verification status.

Requires scopes: Organization.Read.All, Domain.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtTenantInfo
```

Returns tenant organization details.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSObject with properties: tenantId, displayName, tenantType, countryCode, createdDateTime, 
### defaultDomain, initialDomain, verifiedDomainCount, domains (comma-separated).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantInfo.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantInfo.md)

