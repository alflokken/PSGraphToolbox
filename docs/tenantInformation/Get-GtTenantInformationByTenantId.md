---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantInformationByTenantId.md
schema: 2.0.0
---

# Get-GtTenantInformationByTenantId

## SYNOPSIS
Get tenant information by tenant ID.

## SYNTAX

```
Get-GtTenantInformationByTenantId [[-tenantId] <Guid>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves basic tenant information (display name, default domain) 
for any tenant by its ID.
Uses beta API for cross-tenant lookup.

Requires scopes: CrossTenantInformation.ReadBasic.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtTenantInformationByTenantId "00000000-0000-0000-0000-000000000000"
```

Returns tenant information for the specified ID.

## PARAMETERS

### -tenantId
The tenant ID (GUID) to look up.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSObject with cross-tenant information: displayName, defaultDomain, federationBrandName, etc.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantInformationByTenantId.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantInformationByTenantId.md)

