---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/servicePrincipals/Get-GtAgentIdentities.md
schema: 2.0.0
---

# Get-GtAgentIdentities

## SYNOPSIS
Get agent identity service principals (Copilot / Power Platform agents).

## SYNTAX

```
Get-GtAgentIdentities [-IdsOnly] [<CommonParameters>]
```

## DESCRIPTION
\[AI-GENERATED\] This function was generated using Claude Opus 4.8.

Retrieves service principals that represent agent identities, matched via the agentIdentity type
or agent-related tags (power-virtual-agents-*, AgenticInstance).
By default each agent is returned
with its owners and sponsors.
Use -IdsOnly for a lightweight id / appId list that skips the owner
expansion and the per-agent sponsor batch lookup.

Requires scopes: Application.Read.All, Directory.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtAgentIdentities
```

Returns agent identities enriched with owners and sponsors.

### EXAMPLE 2
```
Get-GtAgentIdentities -IdsOnly
```

Returns only id and appId for each agent identity (fast lookup).

## PARAMETERS

### -IdsOnly
Return only id and appId for each agent identity (skips owners expansion and the sponsor lookup).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Default: service principal objects with id, appId, displayName, servicePrincipalType, accountEnabled, appOwnerOrganizationId,
### tags, createdByAppId, appDescription, owners (id, userPrincipalName, displayName) and sponsors (@odata.type, id, displayName, userPrincipalName).
### With -IdsOnly: objects with id and appId.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/servicePrincipals/Get-GtAgentIdentities.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/servicePrincipals/Get-GtAgentIdentities.md)

