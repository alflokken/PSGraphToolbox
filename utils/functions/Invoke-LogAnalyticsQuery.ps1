# when az.accounts refuse to cooperate..
function Invoke-GtLogAnalyticsQuery {
    <#
    .SYNOPSIS
        Execute a KQL query against a Log Analytics workspace.

    .DESCRIPTION
        Queries Log Analytics API directly using OAuth2 authentication via PSAuthClient module.

        Prerequisites:
        - PSAuthClient module (Install-Module PSAuthClient)
        - User must have Reader role (or Log Analytics Reader) on the workspace

        API Limits (no pagination - results returned in single response):
        - Maximum records: 500,000 rows
        - Maximum data size: ~100 MB (64 MB compressed)
        - Maximum query time: 10 minutes
        - Request rate: 200 requests per 30 seconds

        If you need more than 500K rows, split queries by time range or use Azure export.

    .PARAMETER WorkspaceId
        The Log Analytics workspace GUID.

    .PARAMETER Query
        The KQL query string to execute. Use 'take' or 'limit' to control result size.

    .PARAMETER Timespan
        ISO 8601 duration for query time range. Examples: PT1H (1 hour), PT12H (12 hours), P1D (1 day), P7D (7 days), P30D (30 days).

    .PARAMETER ClientId
        Azure AD App Registration client ID. Defaults to Azure CLI well-known client ID.

    .PARAMETER TenantId
        Azure AD tenant ID. If not provided, attempts to get from current MgGraph context.

    .EXAMPLE
        Invoke-GtLogAnalyticsQuery -WorkspaceId $wsId -TenantId $tenantId -Query "SigninLogs | take 10"

    .EXAMPLE
        # Query with time range
        $query = "SigninLogs | where AppId == '38aa3b87-a06d-4817-b275-7a316988d93b' | summarize count() by UserPrincipalName"
        Invoke-GtLogAnalyticsQuery -WorkspaceId $wsId -TenantId $tenantId -Query $query -Timespan "P7D"

    .EXAMPLE
        # Large dataset - split by time
        $results = @()
        foreach ($day in 1..7) {
            $ts = "P{0}D/P{1}D" -f $day, ($day - 1)
            $results += Invoke-GtLogAnalyticsQuery -WorkspaceId $wsId -TenantId $tenantId -Query $query -Timespan $ts
        }

    .NOTES
        Authentication: Uses OAuth2 authorization code flow with PKCE via PSAuthClient.
        First run prompts for interactive login via WebView2. Uses Entra ID v2.0 endpoints.

        API Endpoint: https://api.loganalytics.io/v1/workspaces/{id}/query
        Scope: https://api.loganalytics.io/.defaults
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkspaceId,

        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter()]
        [string]$Timespan,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId = "04b07795-8ddb-461a-bbee-02f9e1bf7b46" # Azure CLI well-known client ID
    )

    # Check for PSAuthClient module
    if ( -not (Get-Module -ListAvailable -Name PSAuthClient) ) { throw "PSAuthClient module required. Install with: Install-Module PSAuthClient -Scope CurrentUser" }
    Import-Module PSAuthClient -ErrorAction Stop

    # If no TenantId provided, try to get from current MgGraph context
    if ( -not $TenantId ) {
        $mgContext = Get-MgContext -ErrorAction SilentlyContinue
        if ($mgContext) { $TenantId = $mgContext.TenantId }
        else { throw "TenantId is required. Provide -TenantId or connect via Connect-MgGraph first." }
        Write-Verbose "Using TenantId from MgGraph context: $TenantId"
    }
    
    # authz and token acquisition using PSAuthClient
    $authParams = @{
        uri           = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize"
        client_id     = $ClientId
        redirect_uri  = "http://localhost"
        scope         = "https://api.loganalytics.io/.default openid" # .default for first-party APIs
        response_type = "code"
        usePkce       = $true
        #customParameters = @{ prompt = "select_account" }
    }
    Write-Verbose "Requesting authorization for Log Analytics API..."
    $authResponse = Invoke-OAuth2AuthorizationEndpoint @authParams
    # token exchange
    $tokenParams = @{
        uri           = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        client_id     = $ClientId
        redirect_uri  = "http://localhost"
        code          = $authResponse.code
        code_verifier = $authResponse.code_verifier
    }

    $tokenResponse = Invoke-OAuth2TokenEndpoint @tokenParams #rt not needed
    $accessToken = $tokenResponse.access_token

    $queryParams = @{
        method = "POST"
        uri = "https://api.loganalytics.io/v1/workspaces/$WorkspaceId/query"
        headers = @{
            "Authorization" = "Bearer $accessToken"
            "Content-Type"  = "application/json"
        }
        body = @{
            query    = $Query
            timespan = $Timespan
        } | ConvertTo-Json
    }

    try { $response = Invoke-RestMethod @queryParams }
    catch { throw $_ }

    # Parse response 
    $results = foreach ( $table in $response.tables ) {
        $columns = $table.columns.name
        foreach ( $row in $table.rows ) {
            $obj = [ordered]@{}
            for ($i = 0; $i -lt $columns.Count; $i++) { $obj[$columns[$i]] = $row[$i] }
            [PSCustomObject]$obj
        }
    }
}
