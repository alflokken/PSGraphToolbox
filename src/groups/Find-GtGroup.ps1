function Find-GtGroup {
    <#
    .SYNOPSIS
    Search for Entra ID groups by displayName (partial match).

    .DESCRIPTION
    Searches Microsoft Entra ID (Azure AD) groups using a partial match on displayName. Returns a list of groups with basic properties (id, displayName, description, createdDateTime, groupTypes, mailEnabled, securityEnabled) by default. Uses Microsoft Graph API (beta version) and supports additional property selection via -AdditionalProperties. Minimum 3 characters required for search string. Results are not paged.

    Requires scopes: Group.Read.All

    .PARAMETER SearchString
    The search string (min 3 chars). Performs partial match on group displayName. Case-insensitive.

    .PARAMETER AdditionalProperties
    Comma-separated list of additional properties to include in the response (e.g., "membershipRule,assignedLabels").

    .EXAMPLE
    Find-GtGroup "Sales"
    Returns all groups with 'Sales' in their displayName.

    .EXAMPLE
    Find-GtGroup "Admin" -AdditionalProperties "membershipRule"
    Returns groups with 'Admin' in displayName, including the membershipRule property.

    .NOTES
    Uses Microsoft Graph API beta version for search capability. Returned properties can be customized. Does not support advanced OData filters.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Find-GtGroup.md
    #>
    [Alias('groupSearch')]
    [CmdletBinding()]
    param(
        [parameter(Position = 0, Mandatory = $true)][ValidateLength(3,99)]
        [String]$SearchString,
        
        [parameter(Mandatory = $false)]
        [ValidatePattern("[a-z0-9,]")]
        [String]$AdditionalProperties
    )

    $queryParams = @{}
    $queryParams.select = "id,displayName,description,createdDateTime,groupTypes,mailEnabled,securityEnabled"
    if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }
    $queryParams.apiVersion = "beta"
    $queryParams.resourcePath = "groups"
    $queryParams.search = "`"displayName:$SearchString`""

    try { return Invoke-GtGraphRequest @queryParams }
    catch { throw $_ }
}