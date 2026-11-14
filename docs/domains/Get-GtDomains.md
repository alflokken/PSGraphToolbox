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

Output properties depend on whether the tenant has federated domains:
- No federated domains: id, authenticationType, isVerified
- At least one federated domain: all domains (sorted by authenticationType) with id, authenticationType, isVerified, isRoot,
  fedDisplayname, fedSigningCert, fedNextSigningCert, fedServiceUrl, fedMfaBehavior.
  The fed* properties are populated only for federated root domains (from their federationConfiguration);
  signing certificates are shortened to their first and last 5 characters.

Requires scopes: Domain.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtDomains
```

Returns all tenant domains, with federation details for federated root domains.

## PARAMETERS

## INPUTS

## OUTPUTS

### Array of domain objects. Properties depend on the tenant's domain configuration (see description).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/domains/Get-GtDomains.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/domains/Get-GtDomains.md)

