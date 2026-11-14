function Get-GtGroupMembers {
    <#
    .SYNOPSIS
    Get members of a group.

    .DESCRIPTION
    Retrieves direct members of an Entra ID group, or with -Transitive all members of nested groups as well.
    Members can be users, groups, devices or service principals; properties that do not apply to a member type are empty.

    Requires scopes: GroupMember.Read.All or Group.Read.All.

    .PARAMETER inputObject
    Group object, displayName, or object ID. Accepts pipeline input. A displayName must match exactly one group.

    .PARAMETER Transitive
    Get transitive members (nested group expansion). Defaults to false.

    .EXAMPLE
    Get-GtGroupMembers -InputObject "Sales Team"
    Returns the direct members of the group 'Sales Team'.

    .EXAMPLE
    "00000000-0000-0000-0000-000000000000" | Get-GtGroupMembers -Transitive
    Returns all members of the group, including members of nested groups.

    .OUTPUTS
    Array of member objects with @odata.type, id, accountEnabled, userPrincipalName, displayName.

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
        if ( $groupId.type -ne "guid" ) {
            $groups = @(Get-GtGroup -InputObject $InputObject -Verbose:$false)
            if ( $groups.Count -ne 1 ) { throw "Group '$($groupId.id)' matched $($groups.Count) groups; specify the group id instead." }
            $groupId = $groups[0].id
        }
        else { $groupId = $groupId.id }

        $endpoint = if ( $Transitive ) { "groups/$groupId/transitiveMembers" } else { "groups/$groupId/members" }
        try { 
            $groupName = (Invoke-GtGraphRequest -resourcePath "groups/$groupId" -select "displayName" -Verbose:$false).displayName
            Write-GtVerbose "Retrieving members for group '$groupName' ($groupId)."
            $members = Invoke-GtGraphRequest -resourcePath $endpoint -select "id,accountEnabled,userPrincipalName,displayName" -PageLimit 999 -Verbose:$false
        }
        catch { throw $_ }

        return $members
    }
}