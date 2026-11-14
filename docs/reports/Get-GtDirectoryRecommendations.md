---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRecommendations.md
schema: 2.0.0
---

# Get-GtDirectoryRecommendations

## SYNOPSIS
Get Entra ID directory recommendations with their impacted resources.

## SYNTAX

```
Get-GtDirectoryRecommendations [<CommonParameters>]
```

## DESCRIPTION
Retrieves directory recommendations (beta) and, for active recommendations whose id starts with a GUID
(tenant-specific recommendations), the impacted resources via batch requests.
Impacted resources are added as the impactedResources property (empty for other recommendations).

Requires scopes: DirectoryRecommendations.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtDirectoryRecommendations
```

Returns all recommendations including impacted resources for active ones.

### EXAMPLE 2
```
Get-GtDirectoryRecommendations | Where-Object { $_.status -eq 'active' -and $_.priority -eq 'high' }
```

Returns active high-priority recommendations.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Array of recommendation objects with id, recommendationType, displayName, featureAreas, insights, category, categoryGroup,
### status, priority, releaseType, requiredLicenses, impactType, impactedResources.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRecommendations.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRecommendations.md)

