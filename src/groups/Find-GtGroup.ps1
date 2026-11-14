function Find-GtGroup {
    <#
    .SYNOPSIS
    Search for Entra ID groups by displayName.

    .DESCRIPTION
    Searches Microsoft Entra ID (Azure AD) groups by displayName ($search, beta endpoint). Matches words in displayName that start with the search string (e.g. 'sales' matches 'EMEA Sales Team'). Returns all matching groups (results are paged automatically) with basic properties (id, displayName, description, createdDateTime, groupTypes, mailEnabled, securityEnabled) by default. Supports additional property selection via -AdditionalProperties. Minimum 3 characters required for search string.

    Requires scopes: Group.Read.All

    .PARAMETER SearchString
    The search string (3-99 chars). Word-prefix match on group displayName. Case-insensitive.

    .PARAMETER AdditionalProperties
    Comma-separated list of additional properties to include in the response (e.g., "membershipRule,assignedLabels").

    .EXAMPLE
    Find-GtGroup "Sales"
    Returns all groups with a word in displayName starting with 'Sales'.

    .EXAMPLE
    Find-GtGroup "Admin" -AdditionalProperties "membershipRule"
    Returns matching groups, including the membershipRule property.

    .NOTES
    Uses the Microsoft Graph beta endpoint. Does not support OData filters; use Invoke-GtGraphRequest -Filter for that.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Find-GtGroup.md
    #>
    [CmdletBinding()]
    param(
        [parameter(Position = 0, Mandatory = $true)][ValidateLength(3,99)]
        [String]$SearchString,
        
        [parameter(Mandatory = $false)]
        [ValidatePattern("^[a-z0-9,]+$")]
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