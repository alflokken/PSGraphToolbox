function Remove-GtMembersFromGroup {
    <#
    .SYNOPSIS
    Remove members from a group.

    .DESCRIPTION
    Removes one or more members from an Entra ID group. Group and Members must be object IDs (GUIDs) or objects with an id property (for example, output from Find-GtGroup or Get-GtUser). Display names and UPNs are not accepted; look up the object first. Members that are not in the group are skipped with a warning. Unless -WhatIf is used or -Confirm is set to $false, you are prompted to confirm (Y/N) before anything is removed. Members are removed one at a time (one DELETE request per member). Writes a summary message to the host.

    Only direct user members can be removed: the membership check reads the group's user members, so groups, devices and service principals are treated as not in the group and skipped.

    Requires scopes: GroupMember.ReadWrite.All.

    .PARAMETER group
    Group object (any object with an id property) or group object ID (GUID). Aliases: id, groupId.

    .PARAMETER members
    Array of member objects (any objects with an id property) or member object IDs (GUIDs) to remove. Alias: memberIds.

    .PARAMETER WhatIf
    Preview changes without making them.

    .PARAMETER Confirm
    Prompt for confirmation (Y/N). Defaults to $true. Set to $false to skip the prompt.

    .EXAMPLE
    Remove-GtMembersFromGroup -group "00000000-0000-0000-0000-000000000000" -members @("11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222")
    Removes two users, identified by object ID, from the group after confirmation.

    .EXAMPLE
    $group = Find-GtGroup "Sales Team" | Select-Object -First 1
    $user = Get-GtUser "user1@zavainc.com"
    Remove-GtMembersFromGroup -group $group -members $user -WhatIf
    Shows what would be removed using group and user objects (their id property is used) without making changes.

    .EXAMPLE
    Remove-GtMembersFromGroup -group "00000000-0000-0000-0000-000000000000" -members "11111111-1111-1111-1111-111111111111" -Confirm:$false
    Removes a user from the group without prompting for confirmation.

    .OUTPUTS
    None. Progress and results are written to the host.

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
    $groupId = Get-IdFromInputObject -inputObject $Group -objectIdOnly | Select-Object -ExpandProperty id
    
    # resolve group displayName 
    if ( $group.PSObject.Properties.Name -notcontains "displayName" ) {
        try { $group = Invoke-GtGraphRequest -resourcePath "groups/$groupId" -select "id,displayName" -Verbose:$false }
        catch { throw "Failed to retrieve group details for groupId '$groupId'. $_" }
    }

    # members validation
    $memberIds = foreach ( $member in $Members ) { Get-IdFromInputObject -inputObject $member -objectIdOnly | Select-Object -ExpandProperty id }
    
    # members - check for duplicates
    $originalCount = @($memberIds).Count
    $memberIds = $memberIds | Select-Object -Unique
    if ( @($memberIds).Count -lt $originalCount ) { Write-Warning "Duplicate member IDs found. Removed $($originalCount - @($memberIds).Count) duplicates." }

    # identify existing groupMembers
    Write-GtVerbose "Retrieving existing members of group '$($group.displayName)' ($groupId)..."
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

    Write-GtVerbose "Removing $totalMembers member(s) from group '$($group.displayName)' ($groupId)..."

    foreach ( $memberId in $membersToRemove ) {
        $memberIndex++
        try { 
            if ( $WhatIf ) { 
                Write-Host "WhatIf: Would remove memberId '$memberId' from groupId '$groupId' ($memberIndex/$totalMembers)." -ForegroundColor Yellow
                $removedCount++
                continue
            }
            Write-GtVerbose "Removing member $memberIndex/$totalMembers ($memberId)..."
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