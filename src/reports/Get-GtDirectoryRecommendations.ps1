function Get-GtDirectoryRecommendations {
    <#
    .SYNOPSIS
    Get Entra ID directory recommendations with their impacted resources.

    .DESCRIPTION
    Retrieves directory recommendations (beta) and, for active recommendations whose id starts with a GUID
    (tenant-specific recommendations), the impacted resources via batch requests.
    Impacted resources are added as the impactedResources property (empty for other recommendations).

    Requires scopes: DirectoryRecommendations.Read.All.

    .OUTPUTS
    Array of recommendation objects with id, recommendationType, displayName, featureAreas, insights, category, categoryGroup,
    status, priority, releaseType, requiredLicenses, impactType, impactedResources.

    .EXAMPLE
    Get-GtDirectoryRecommendations
    Returns all recommendations including impacted resources for active ones.

    .EXAMPLE
    Get-GtDirectoryRecommendations | Where-Object { $_.status -eq 'active' -and $_.priority -eq 'high' }
    Returns active high-priority recommendations.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRecommendations.md
    #>
    [CmdletBinding()]
    param()
    $directoryRecommendations = Invoke-GtGraphRequest -ResourcePath "directory/recommendations" -ApiVersion beta | select id,recommendationType,displayName,featureAreas,insights,category,categoryGroup,status,priority,releaseType,requiredLicenses,impactType

    $impactedResourceRequests = $directoryRecommendations | Where-Object { $_.status -eq 'active' -and (isValidGuid ($_.id -split '_')[0])} | Foreach-Object {
        @{ id = $_.id; method = "GET"; url = "directory/recommendations/$($_.id)/impactedResources" }
    }
    $impactedResourceById = @{}
    if ( $impactedResourceRequests ) { $impactedResourceById = Invoke-GtGraphBatchRequest -Requests $impactedResourceRequests -ApiVersion beta }

    foreach ( $rec in $directoryRecommendations ) {
        $impactedResources = $impactedResourceById[$rec.id]
        $rec | Add-Member -NotePropertyName impactedResources -NotePropertyValue $impactedResources
    }
    return $directoryRecommendations
}