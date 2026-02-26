---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/domains/Get-GtDomains.md
schema: 2.0.0
---

# Get-GtDomains

## SYNOPSIS
Get tenant domains with federation configuration.

## SYNTAX

```
Get-GtDomains
```

## DESCRIPTION
Retrieves all domains registered in the tenant.
For federated domains,
enriches with federation configuration (signing certs, SSO URLs, MFA behavior).

Output properties vary by domain type:
- Managed domains: id, authenticationType, isVerified, isRoot
- Federated domains: Above plus fedDisplayname, fedServiceUrl, fedSigningCert, fedNextSigningCert, fedMfaBehavior

Requires scopes: Domain.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtDomains
```

Returns all tenant domains with federation details.

## PARAMETERS

## INPUTS

## OUTPUTS

### Array of domain objects. Properties depend on authentication type (see description).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/domains/Get-GtDomains.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/domains/Get-GtDomains.md)

