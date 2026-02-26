function New-GtRequestUri {
    <#
    .SYNOPSIS
    Construct a Graph API URI with OData query parameters.

    .DESCRIPTION
    Builds a properly formatted and escaped Graph API URI from individual OData parameters.
    Used internally by Invoke-GtGraphRequest.

    .PARAMETER resourcePath
    The Graph API resource path (version prefix stripped if included).

    .PARAMETER filter
    OData $filter expression.

    .PARAMETER select
    Comma-separated list of properties.

    .PARAMETER search
    OData $search expression.

    .PARAMETER orderBy
    OData $orderby expression.

    .PARAMETER expand
    OData $expand expression.

    .PARAMETER top
    Maximum results per page.

    .PARAMETER count
    Include $count=true in query.

    .PARAMETER apiVersion
    API version: "v1.0" or "beta". Defaults to "v1.0".

    .OUTPUTS
    String containing the constructed URI.

    .EXAMPLE
    New-GtRequestUri -resourcePath "users" -filter "accountEnabled eq true" -select "id,displayName"

    Constructs a Graph API URI with filter and select parameters.
    Returns: v1.0/users?$filter=accountEnabled%20eq%20true&$select=id,displayName

    .EXAMPLE
    New-GtRequestUri -resourcePath "groups" -apiVersion "beta" -top 10 -count -select "id,displayName,membershipRule"

    Constructs a beta API URI for groups with top, count, and select parameters.
    Returns: beta/groups?$select=id,displayName,membershipRule&$top=10&$count=true

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/New-GtRequestUri.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$resourcePath,

        [string]$filter,
        [string]$select,
        [string]$search,

        [string]$orderBy,
        [string]$expand,
        [int]$top,
        [switch]$count,

        [ValidateSet("v1.0", "beta")]
        [string]$apiVersion = "v1.0"
    )
    if ( $resourcePath -match '^beta/' -and $apiVersion -eq 'v1.0' ) { Write-Debug "Resource path indicates 'beta' version, but apiVersion is set to 'v1.0'. Overriding apiVersion to 'beta'."; $apiVersion = "beta" }
    $resourcePath = $resourcePath -replace '^(.*v1\.0|.*beta)/',''  # remove version prefix if included in the resourcePath

    $query = @()
    if ( $filter )   { $query += "`$filter=" + [uri]::EscapeDataString($filter) }   # OData filter, supports expressions like eq, startswith()
    if ( $select )   { $query += "`$select=$( ($select -split "," | ForEach-Object { $_ -replace "\s" } | Where-Object { $_ } | Select-Object -Unique) -join "," )" } # dedupe
    if ( $search )   { $query += "`$search=" + [uri]::EscapeDataString($search) }   # Full-text search; must be quoted and requires ConsistencyLevel header
    if ( $orderBy )  { $query += "`$orderby=" + [uri]::EscapeDataString($orderBy) } # Sort results, e.g. 'displayName desc'
    if ( $top )      { $query += "`$top=$top" }                                     # Limit number of returned results
    if ( $count )    { $query += "`$count=true" }                                   # Include result count; requires ConsistencyLevel header
    if ( $expand )   { $query += "`$expand=" + [uri]::EscapeDataString($expand) }   # Expand related entities
    
    # return constructed URI
    if ($query)    { return "$apiVersion/$resourcePath" + "?" + ($query -join '&') }
    else           { return "$apiVersion/$resourcePath" }
}