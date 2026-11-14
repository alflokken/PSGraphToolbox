function Get-GtGraphDirectoryObjectsByIds {
    <#
    .SYNOPSIS
    Bulk lookup of directory objects by ID.

    .DESCRIPTION
    Retrieves multiple directory objects by their object IDs using directoryObjects/getByIds.
    IDs are sent in chunks of 1000 (API limit), one POST request per chunk.

    More efficient than individual lookups when resolving many IDs.

    Requires scopes: Directory.Read.All.

    .PARAMETER Type
    Object types to return. Accepts multiple values: application, administrativeUnit, appRoleAssignment,
    directoryObject, directoryRole, device, group, orgContact, user, servicePrincipal.
    Use directoryObject on its own to return objects of any type (no type filter).

    .PARAMETER Ids
    Array of object IDs (GUIDs) to look up.

    .OUTPUTS
    Array of directory objects (including @odata.type) matching the specified IDs and types.
    IDs that are not found, or not of the requested type, are omitted. dateTime values are converted to local time.

    .EXAMPLE
    Get-GtGraphDirectoryObjectsByIds -Type user -Ids @("guid1", "guid2")
    Returns user objects for the specified IDs.

    .EXAMPLE
    Get-GtGraphDirectoryObjectsByIds -Type user,group -Ids $mixedIds
    Returns users and groups matching any of the specified IDs.

    .EXAMPLE
    Get-GtGraphDirectoryObjectsByIds -Type directoryObject -Ids $principalIds | ConvertTo-HashTable
    Resolves IDs of any object type and builds a lookup hashtable keyed by id.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Get-GtGraphDirectoryObjectsByIds.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, HelpMessage="types")] 
        [ValidateSet('application','administrativeUnit','appRoleAssignment','directoryObject','directoryRole','device','group','orgContact','user','servicePrincipal')]
        [array]$Type,
        [Parameter(Position = 1, Mandatory = $true)] 
        [array]$Ids
    )

    $response = @()
    $chunks = Split-ArrayIntoChunks -Enumerable $Ids -ChunkSize 1000

    foreach ( $chunk in $chunks ) {
        try { 
            $body = @{ ids = $chunk } 
            if ( $Type -ne 'directoryObject' ) { $body.types = [array]$Type }
            $response += Invoke-MgGraphRequest -uri "v1.0/directoryObjects/getByIds" -Method POST -Body ($body | ConvertTo-Json) -OutputType PSObject | Select-Object -ExpandProperty value
        }
        catch { throw $_ }
    }

    # convert dateTime values (UTC -> local) in place
    $null = ConvertTo-GtLocalDateTime -InputObject $response
    return $response 
}