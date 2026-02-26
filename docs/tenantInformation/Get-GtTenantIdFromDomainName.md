---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantIdFromDomainName.md
schema: 2.0.0
---

# Get-GtTenantIdFromDomainName

## SYNOPSIS
Get tenant ID from a domain name.

## SYNTAX

```
Get-GtTenantIdFromDomainName [[-domainName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Looks up the Entra ID tenant ID for a domain using the public
OpenID Connect discovery endpoint.
Works without authentication.

## EXAMPLES

### EXAMPLE 1
```
Get-GtTenantIdFromDomainName "zavainc.com"
```

Returns tenant ID for zavainc.com.

### EXAMPLE 2
```
"zavainc.com" | Get-GtTenantIdFromDomainName
```

Pipeline input supported.

## PARAMETERS

### -domainName
Domain name to look up (e.g., "zavainc.com").

```yaml
Type: String
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

### PSObject with domainName and tenantId.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantIdFromDomainName.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantIdFromDomainName.md)

