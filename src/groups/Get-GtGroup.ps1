function Get-GtGroup {
    <#
    .SYNOPSIS
    Get a group from Entra ID by object ID, displayName, or group object.

    .DESCRIPTION
    Retrieves a Microsoft Entra ID group by object ID, displayName, or group object. Accepts pipeline input. Returns group properties (id, displayName, description, createdDateTime, groupTypes, mailEnabled, securityEnabled) by default. Additional properties can be requested via -AdditionalProperties. Throws if the group is not found.

    Requires scopes: Group.Read.All

    .PARAMETER InputObject
    Group object (with id), displayName, or object ID. Accepts pipeline input. Alias: id.

    .PARAMETER AdditionalProperties
    Comma-separated list of additional properties to include in the response (e.g., "membershipRule,assignedLabels").

    .EXAMPLE
    Get-GtGroup "Sales Team"
    Returns the group(s) with displayName 'Sales Team'.

    .EXAMPLE
    "00000000-0000-0000-0000-000000000000" | Get-GtGroup
    Returns the group with the specified object ID.

    .EXAMPLE
    Get-GtGroup $groupObj -AdditionalProperties "membershipRule"
    Returns the group with additional property 'membershipRule'.

    .NOTES
    displayName lookups use an exact (case-insensitive) match. If several groups share the displayName, all of them are returned. Additional properties must be valid Graph API group properties.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroup.md
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [Alias('id')]
        $InputObject,

        [parameter(Mandatory = $false)]
        [ValidatePattern("^[a-z0-9,]+$")]
        [String]$AdditionalProperties
    )
    process {

        $groupId = Get-IdFromInputObject $InputObject -AllowRawString

        $queryParams = @{}
        $queryParams.select = "id,displayName,description,createdDateTime,groupTypes,mailEnabled,securityEnabled"
        if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }

        if ( $groupId.type -eq "guid" ) { $queryParams.resourcePath = "groups/$($groupId.id)" }
        else { 
            $queryParams.resourcePath = "groups"
            $queryParams.filter = "displayName eq '$($groupId.id -replace "'", "''")'" 
        }

        try { 
            $response = Invoke-GtGraphRequest @queryParams
            if ( !$response ) { throw "Get-GtGroup '$($groupId.id)' not found." }
            return $response
        }
        catch { throw $_ }
    }
}