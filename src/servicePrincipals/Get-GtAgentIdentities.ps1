function Get-GtAgentIdentities {
    <#
    .SYNOPSIS
    Get agent identity service principals (Copilot / Power Platform agents).

    .DESCRIPTION
    [AI-GENERATED] This function was generated using Claude Opus 4.8.

    Retrieves service principals that represent agent identities, matched via the agentIdentity type
    or agent-related tags (power-virtual-agents-*, AgenticInstance). By default each agent is returned
    with its owners and sponsors. Use -IdsOnly for a lightweight id / appId list that skips the owner
    expansion and the per-agent sponsor batch lookup.

    Requires scopes: Application.Read.All, Directory.Read.All.

    .PARAMETER IdsOnly
    Return only id and appId for each agent identity (skips owners expansion and the sponsor lookup).

    .OUTPUTS
    Default: service principal objects with id, appId, displayName, servicePrincipalType, accountEnabled, appOwnerOrganizationId,
    tags, createdByAppId, appDescription, owners (id, userPrincipalName, displayName) and sponsors (@odata.type, id, displayName, userPrincipalName).
    With -IdsOnly: objects with id and appId.

    .EXAMPLE
    Get-GtAgentIdentities
    Returns agent identities enriched with owners and sponsors.

    .EXAMPLE
    Get-GtAgentIdentities -IdsOnly
    Returns only id and appId for each agent identity (fast lookup).

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/servicePrincipals/Get-GtAgentIdentities.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IdsOnly
    )

    $agentFilter = "(isof('microsoft.graph.agentIdentity') OR (tags/any(p:startswith(p, 'power-virtual-agents-')) OR tags/any(p:p eq 'AgenticInstance')))"

    # fast path: id/appId only, no owners expansion or sponsor batch
    if ( $IdsOnly ) {
        return Invoke-GtGraphRequest "v1.0/servicePrincipals" -filter $agentFilter -Select "id,appId"
    }

    $agentIdentities = Invoke-GtGraphRequest "v1.0/servicePrincipals" -filter $agentFilter `
        -Select "id,appId,displayName,servicePrincipalType,accountEnabled,appOwnerOrganizationId,tags,createdByAppId,appDescription" `
        -expand "owners(`$select=id,userPrincipalName,displayName)" | select *, sponsors
    if ( -not $agentIdentities ) { return }
    # batch: get sponsors for each agentIdentity
    $sponsorRequest = @(
        $agentIdentities | ForEach-Object {
            @{
                id     = $_.id
                method = "GET"
                url    = "servicePrincipals/$($_.id)/sponsors" # select not supported on directoryObjects relationships
            }
        }
    )
    $sponsorResponse = Invoke-GtGraphBatchRequest -requests $sponsorRequest -verbose:$false
    # merge
    foreach ( $agent in $agentIdentities ) { $agent.sponsors = $sponsorResponse[$agent.id] | select '@odata.type',id,displayName,userPrincipalName }

    return $agentIdentities
}