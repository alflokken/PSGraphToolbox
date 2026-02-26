function Get-GtGraphDirectoryObjectsByIds {
    <#
    .SYNOPSIS
    Bulk lookup of directory objects by ID.

    .DESCRIPTION
    Retrieves multiple directory objects (users, groups, devices) by their object IDs
    in a single API call. Automatically chunks requests into batches of 1000 (API limit).

    More efficient than individual lookups when resolving many IDs.

    Requires scopes: Directory.Read.All.

    .PARAMETER Type
    Object types to return: user, group, device. Accepts multiple values.

    .PARAMETER Ids
    Array of object IDs (GUIDs) to look up.

    .OUTPUTS
    Array of directory objects matching the specified IDs and types.

    .EXAMPLE
    Get-GtGraphDirectoryObjectsByIds -Type user -Ids @("guid1", "guid2")
    Returns user objects for the specified IDs.

    .EXAMPLE
    Get-GtGraphDirectoryObjectsByIds -Type user,group -Ids $mixedIds
    Returns users and groups matching any of the specified IDs.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Get-GtGraphDirectoryObjectsByIds.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, HelpMessage="types")] 
        [ValidateSet('user','group','device')]
        [array]$Type,
        [Parameter(Position = 1, Mandatory = $true)] 
        [array]$Ids
    )

    $response = @()
    $chunks = Split-ArrayIntoChunks -Enumerable $Ids -ChunkSize 1000

    foreach ( $chunk in $chunks ) {
        try { 
            $body = @{ 
                types = [array]$Type 
                ids = $chunk
            } | ConvertTo-Json
            $response += Invoke-MgGraphRequest -uri "v1.0/directoryObjects/getByIds" -Method POST -Body $body -OutputType PSObject | Select-Object -ExpandProperty value
        }
        catch { throw $_ }
    }

    return $response 
}