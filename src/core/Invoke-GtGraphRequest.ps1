function Invoke-GtGraphRequest {
    <#
    .SYNOPSIS
    Wrapper for Invoke-MgGraphRequest with automatic pagination and OData support.

    .DESCRIPTION
    Simplifies Microsoft Graph API calls by handling:
    - Automatic pagination (@odata.nextLink processing)
    - OData query parameters as native PowerShell parameters
    - ConsistencyLevel header for $search and $count queries
    - Delta query support with deltaLink tracking
    - Automatic Graph connection (Connect-MgGraph) if not already connected
    - Throttling retry policy, configured once per session (Set-MgRequestContext -RetryDelay 10 -MaxRetry 5)
    - Recursive conversion of all dateTime values from UTC to local time

    GET requests only; use Invoke-MgGraphRequest for POST/PATCH/DELETE.

    Requires scopes: Varies by resource path.

    .PARAMETER ResourcePath
    The Graph API resource path (e.g., "users", "groups/xxx/members").
    A version prefix (v1.0/ or beta/) is removed; a "beta/" prefix (without a leading slash) also switches the request to the beta endpoint.
    A full https:// URL (e.g. a nextLink or deltaLink) is used as-is; the OData parameters are then ignored.

    .PARAMETER ApiVersion
    Graph API version: "v1.0" or "beta". Defaults to "v1.0".

    .PARAMETER Filter
    OData $filter expression (e.g., "accountEnabled eq true").

    .PARAMETER Search
    OData $search expression. Requires quoted strings (e.g., '"displayName:john"').
    Automatically adds ConsistencyLevel: eventual header.

    .PARAMETER Select
    Comma-separated list of properties to return.

    .PARAMETER OrderBy
    OData $orderby expression (e.g., "displayName desc").

    .PARAMETER Expand
    OData $expand expression for related entities.
    For relationships of directory objects (owners, memberOf, appRoleAssignments, ...), Graph typically returns at 
    most 20 expanded items and no nextLink; query the relationship directly for complete results.

    .PARAMETER Top
    Page size ($top): maximum number of results per page. Paging still continues until all results
    (or -PageLimit pages) are retrieved, so this does not limit the total number of results.

    .PARAMETER Count
    Include total count in response. Adds ConsistencyLevel: eventual header.

    .PARAMETER AdditionalHeaders
    Hashtable of additional HTTP headers to include.

    .PARAMETER PageLimit
    Maximum number of pages to retrieve. Defaults to 100.
    A "Result truncated" warning is written whenever this number of pages is reached.

    .PARAMETER AccessToken
    SecureString access token for authentication (optional).
    When supplied, Connect-MgGraph -AccessToken is called on every invocation, even if already connected.

    .OUTPUTS
    For single resources: PSObject with resource properties (@odata.* properties removed).
    For collections: Array of PSObjects (items of all retrieved pages).
    For delta queries: PSObject with value, deltaLink, and dateRetrieved.

    All dateTime values in the returned objects are converted from UTC to local time.

    .EXAMPLE
    Invoke-GtGraphRequest -ResourcePath "users" -Select "id,displayName"
    Returns all users with id and displayName.

    .EXAMPLE
    Invoke-GtGraphRequest -ResourcePath "users" -Filter "accountEnabled eq true" -Top 999
    Returns all enabled users, retrieved 999 per page.

    .EXAMPLE
    Invoke-GtGraphRequest -ResourcePath "users" -Search '"displayName:john"' -Select "id,displayName"
    Searches users with 'john' in displayName.

    .EXAMPLE
    Invoke-GtGraphRequest -ResourcePath "users" -ApiVersion beta -Select "id,signInActivity"
    Uses beta API to get sign-in activity data.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Invoke-GtGraphRequest.md
    #>
    [CmdletBinding()]
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [string]$ResourcePath,
        [ValidateSet("v1.0", "beta")]
        [string]$ApiVersion = "v1.0",
        [string]$Filter,
        [string]$Search,
        [string]$Select,
        [string]$OrderBy,
        [string]$Expand,
        [int]$Top,
        [switch]$Count,
        [hashtable]$AdditionalHeaders,
        [int]$PageLimit = 100,
        [securestring]$AccessToken
    )

    # connection
    if ( $null -eq (Get-MgContext) -or $AccessToken) { 
        if ( $AccessToken ) { Connect-MgGraph -AccessToken $AccessToken -NoWelcome | Out-Null }
        else { Connect-MgGraph -NoWelcome | Out-Null }
    }

    # retry policy (set once)
    if ( -not $Global:_GtGraphRetryConfigured ) {
        Write-Debug "Invoke-GtGraphRequest: Configured MgRequestContext for request throttling (RetryDelay=10s, MaxRetry=5)"
        Set-MgRequestContext -RetryDelay 10 -MaxRetry 5 -ErrorAction SilentlyContinue | Out-Null
        $Global:_GtGraphRetryConfigured = $true
    }

    # init vars
    [int]$currentPage = 0
    [object]$response = $null
    [Array]$responseArray = @()
    [hashtable]$headers = $null

    # add additional headers if provided
    if ( $AdditionalHeaders ) { $headers = @{} + $AdditionalHeaders }

    # add ConsistencyLevel header if search or count is used
    if ( $Search -or $Count ) { 
        if ( -not $headers ) { $headers = @{} }
        $headers["ConsistencyLevel"] = "eventual" 
    }

    # build url with query odata params
    # If ResourcePath is already a full URL (e.g., deltaLink), use it directly; otherwise construct via New-GtRequestUri
    if ( $ResourcePath -match '^https://' ) { $uri = $ResourcePath }
    else { $uri = New-GtRequestUri -Filter $Filter -Search $Search -Select $Select -OrderBy $OrderBy -Top $Top -Count:$Count -Expand $Expand -ApiVersion $ApiVersion -ResourcePath $ResourcePath }
    
    do {
        $params = @{
            Uri = $uri
            OutputType = 'PSObject'
        }
        if ( $headers ) { $params.Headers = $headers }
        if ( $currentPage -ne 0 ) { $params.Uri = $response.'@odata.nextLink' }
        
        Write-GtVerbose "Invoke-MgGraphRequests: Retrieving page $($currentPage + 1)"
        try { 
            $response = Invoke-MgGraphRequest @params
            # collection (delta or paginated) or single-resource response (flat)
            if ( $response.PSObject.Properties.Name -contains 'value' ) { $responseArray += $response.value }
            else { return (ConvertTo-GtLocalDateTime -InputObject ($response | Select-Object -Property * -ExcludeProperty "@odata.*")) }
            $currentPage++
        }
        catch { throw $_ }

        if ( $currentPage -ge $PageLimit -and $response.'@odata.nextLink' ) { Write-Warning "Invoke-MgGraphRequests: pageLimit $($PageLimit) reached. Result truncated." }
    } while ( $response.'@odata.nextLink' -and $currentPage -lt $PageLimit )

    # if deltaLink present, wrap response in object with deltaLink and dateRetrieved
    if ( $response.PSObject.Properties.Name -contains "@odata.deltaLink" ) { 
        $Obj = New-Object -TypeName PSObject
        $Obj | Add-Member -NotePropertyName "value" -NotePropertyValue $responseArray
        # Preserve API version in deltaLink - Graph may return v1.0 even when beta was requested
        # This ensures subsequent delta queries use the same API version as the initial request
        $deltaLink = $response.'@odata.deltaLink'
        if ( $ApiVersion -eq 'beta' -and $deltaLink -match 'graph\.microsoft\.com/v1\.0/' ) {
            $deltaLink = $deltaLink -replace 'graph\.microsoft\.com/v1\.0/', 'graph.microsoft.com/beta/'
            Write-GtVerbose "Invoke-GtGraphRequest: Adjusted deltaLink to use beta API version"
        }
        $Obj | Add-Member -NotePropertyName "deltaLink" -NotePropertyValue $deltaLink
        $Obj | Add-Member -NotePropertyName "dateRetrieved" -NotePropertyValue ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
        $responseArray = $Obj
    }

    # convert all dateTime values (UTC -> local) recursively before returning
    return (ConvertTo-GtLocalDateTime -InputObject $responseArray)
}