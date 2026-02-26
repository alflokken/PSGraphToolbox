function Get-GtGroupMembers {
    <#
    .SYNOPSIS
    Get members of a group.

    .DESCRIPTION
    Retrieves members of an Entra ID group.
    Supports transitive membership lookup.

    Requires scopes: GroupMember.Read.All or Group.Read.All.

    .PARAMETER inputObject
    Group object, displayName, or object ID.

    .PARAMETER Transitive
    Get transitive members (nested group expansion). Defaults to false.

    .EXAMPLE
    Get-GtGroupMembers -InputObject "Sales Team"

    .EXAMPLE
    "00000000-0000-0000-0000-000000000000" | Get-GtGroupMembers -Transitive

    .OUTPUTS
    Array of member objects with id, accountEnabled, userPrincipalName, displayName.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Get-GtGroupMembers.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,

        [Parameter()]
        [switch]$Transitive
    )
    process {
        # Establish group ID
        $groupId = Get-idFromInputObject $InputObject -AllowRawString
        if ( $groupId.type -ne "guid" ) { $groupId = Get-GtGroup -InputObject $InputObject -Verbose:$false | Select-Object -ExpandProperty id }
        else { $groupId = $groupId.id }

        $endpoint = if ( $Transitive ) { "groups/$groupId/transitiveMembers" } else { "groups/$groupId/members" }
        try { 
            $groupName = (Invoke-GtGraphRequest -resourcePath "groups/$groupId" -select "displayName" -Verbose:$false).displayName
            Write-Verbose "Retrieving members for group '$groupName' ($groupId)."
            $members = Invoke-GtGraphRequest -resourcePath $endpoint -select "id,accountEnabled,userPrincipalName,displayName" -Verbose:$false
        }
        catch { throw $_ }

        return $members
    }
}