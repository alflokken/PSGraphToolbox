function Remove-GtMembersFromGroup {
    <#
    .SYNOPSIS
    Remove members from a group.

    .DESCRIPTION
    Removes one or more members from an Entra ID group.

    Requires scopes: GroupMember.ReadWrite.All.

    .PARAMETER group
    Group object, displayName, or object ID.

    .PARAMETER members
    Array of member objects, UPNs, or object IDs to remove.

    .PARAMETER WhatIf
    Preview changes without making them.

    .PARAMETER Confirm
    Prompt for confirmation. Defaults to true.

    .EXAMPLE
    Remove-GtMembersFromGroup -group "Sales Team" -members @("user1@zavainc.com")

    .OUTPUTS
    Summary object with removedCount and timestamp properties.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Remove-GtMembersFromGroup.md
    #>
    param (
        [parameter(Mandatory)]
        [Alias('id','groupId')]
        [Object]$Group,
        [parameter(Mandatory)]
        [Alias('memberIds')]
        [Object]$Members,
        [switch]$WhatIf,
        [bool]$Confirm = $true
    )

    # group validation
    $groupId = idFromInputObject -inputObject $Group -objectIdOnly | Select-Object -ExpandProperty id
    
    # resolve group displayName 
    if ( $group.PSObject.Properties.Name -notcontains "displayName" ) {
        try { $group = Invoke-GtGraphRequest -resourcePath "groups/$groupId" -select "id,displayName" -Verbose:$false }
        catch { throw "Failed to retrieve group details for groupId '$groupId'. $_" }
    }

    # members validation
    $memberIds = foreach ( $member in $Members ) { Get-idFromInputObject -inputObject $member -objectIdOnly | Select-Object -ExpandProperty id }
    
    # members - check for duplicates
    $originalCount = @($memberIds).Count
    $memberIds = $memberIds | Select-Object -Unique
    if ( @($memberIds).Count -lt $originalCount ) { Write-Warning "Duplicate member IDs found. Removed $($originalCount - @($memberIds).Count) duplicates." }

    # identify existing groupMembers
    Write-Verbose "Retrieving existing members of group '$($group.displayName)' ($groupId)..."
    try { $existingMembers = Invoke-GtGraphRequest -resourcePath "groups/$groupId/members/microsoft.graph.user" -select "id,userPrincipalName" -top 999 -Verbose:$false }
    catch { throw "Failed to retrieve existing group members for groupId '$groupId'. $_" }

    # determine members to remove or skip
    $membersToRemove = $memberIds | Where-Object { $_ -in $existingMembers.id }
    $notMembers = $memberIds | Where-Object { $_ -notin $existingMembers.id }
    if ( $notMembers.Count -gt 0 ) { 
        Write-Warning "$($notMembers.Count) member(s) are not in the group. They will be skipped."
        $notMembers | ForEach-Object { Write-Debug "Member '$_' is not in the group" }
        if ( $membersToRemove.Count -eq 0 ) { 
            Write-Host "No members to remove. Exiting." -ForegroundColor Yellow
            return
        }
    }

    # confirm (constrained language mode does not support ShouldProcess)
    if ( $Confirm -and -not $WhatIf ) {
        $confirmation = Read-Host "Are you sure you want to remove $($membersToRemove.Count) members from groupId '$groupId'? (Y/N)"
        if ( $confirmation -ne "Y" -and $confirmation -ne "y" ) {
            Write-Host "Operation cancelled by user." -ForegroundColor Yellow
            return
        }
    }

    $totalMembers = @($membersToRemove).Count
    $removedCount = 0
    $memberIndex = 0

    Write-Verbose "Removing $totalMembers member(s) from group '$($group.displayName)' ($groupId)..."

    foreach ( $memberId in $membersToRemove ) {
        $memberIndex++
        try { 
            if ( $WhatIf ) { 
                Write-Host "WhatIf: Would remove memberId '$memberId' from groupId '$groupId' ($memberIndex/$totalMembers)." -ForegroundColor Yellow
                $removedCount++
                continue
            }
            Write-Verbose "Removing member $memberIndex/$totalMembers ($memberId)..."
            Invoke-MgGraphRequest -method DELETE -uri "/v1.0/groups/$groupId/members/$memberId/`$ref" -OutputType PSObject -StatusCodeVariable statusCode -debug:$false 
            if ( $statusCode -ne 204 ) { throw "Failed to remove memberId '$memberId' from groupId '$groupId'. Status code: $statusCode" }
            $removedCount++
        }
        catch { throw "Failed to remove memberId '$memberId' from groupId '$groupId'. $_" }
    }

    # Summary
    if ( $WhatIf ) { Write-Host "WhatIf: Would have removed $removedCount member(s) from group '$($group.displayName)' ($groupId)." -ForegroundColor Yellow }
    else { Write-Host "Successfully removed $removedCount member(s) from group '$($group.displayName)' ($groupId)." -ForegroundColor Green }
}