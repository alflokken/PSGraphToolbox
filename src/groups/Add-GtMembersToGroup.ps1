function Add-GtMembersToGroup {
    <#
    .SYNOPSIS
    Adds one or more members to an Entra ID (Azure AD) group with batching, duplicate, and membership checks.

    .DESCRIPTION
    Adds one or more users to a Microsoft Entra ID group. Accepts group and member input as objects, display names, UPNs, or object IDs. Handles batching (20 per request), removes duplicate members, and skips users already in the group (unless -skipMembershipCheck is used). Provides summary output and supports -WhatIf for dry-run preview. Throws on errors and warns for non-fatal issues (e.g., already a member).

    Requires scopes: GroupMember.ReadWrite.All

    .PARAMETER Group
    Group object, displayName, or object ID. Accepts pipeline input.

    .PARAMETER Members
    Array of member objects, UPNs, or object IDs to add. Accepts pipeline input.

    .PARAMETER skipMembershipCheck
    If specified, skips checking for existing group membership. May cause errors if some members are already present.

    .PARAMETER WhatIf
    Preview changes without making them.

    .EXAMPLE
    Add-GtMembersToGroup -Group "Sales Team" -Members @("user1@zavainc.com", "user2@zavainc.com")
    Adds two users to the "Sales Team" group, skipping any already present.

    .EXAMPLE
    Add-GtMembersToGroup -Group $groupObj -Members $userList -WhatIf
    Shows what would be added without making changes.

    .EXAMPLE
    Add-GtMembersToGroup -Group "00000000-0000-0000-0000-000000000000" -Members "user@zavainc.com" -skipMembershipCheck
    Attempts to add a user to a group without checking if they are already a member.

    .OUTPUTS
    Summary object with addedCount, skippedCount, and errorCount properties.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Add-GtMembersToGroup.md
    #>
    param (
        [parameter(Mandatory)]
        [Alias('id','groupId')]
        [Object]$Group,
        [parameter(Mandatory)]
        [Alias('memberIds')]
        [Object]$Members,
        [Switch]$skipMembershipCheck,
        [switch]$WhatIf
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
    $originalCount = $memberIds.count
    $memberIds = $memberIds | Select-Object -Unique
    if ( $memberIds.count -lt $originalCount ) { write-warning "Duplicate member IDs found. Removed $($originalCount - $memberIds.count) duplicates." }

    if ( -not $skipMembershipCheck ) {
        # identify existing groupMembers - these must be skipped (as Graph API will error if adding existing members, even in batch)
        Write-Verbose "Retrieving existing members of group '$($group.displayName)' ($groupId)..." 
        try { $existingMembers = Invoke-GtGraphRequest -resourcePath "groups/$groupId/members/microsoft.graph.user" -select "id,userPrincipalName" -top 999 -Verbose:$false }
        catch { throw "Failed to retrieve existing group members for group '$($group.displayName)'. $_" }

        # determine members to add or skip
        $membersToAdd = $memberIds | where { $_ -notin $existingMembers.id }
        $alreadyMembers = $memberIds | where { $_ -in $existingMembers.id }
        if ( $alreadyMembers.count -gt 0 ) { 
            write-warning "$($alreadyMembers.count) members are already in the group. They will be skipped." 
            $alreadyMembers | %{ Write-Debug "member '$($_)' already in group" }
            if ( $membersToAdd.count -eq 0 ) { 
                write-host "No new members to add. Exiting." -ForegroundColor Yellow
                return
            }
        }
    }
    else { 
        Write-Verbose "Skipping membership check."
        $membersToAdd = $memberIds
    }

    # split into chunks of 20 (Graph API batch limit)
    $chunks = Split-ArrayIntoChunks -Enumerable ($membersToAdd | %{ "https://graph.microsoft.com/v1.0/directoryObjects/" + $_ }) -ChunkSize 20
    $totalChunks = @($chunks).Count
    $addedCount = 0

    Write-Verbose "Adding $($membersToAdd.Count) members in $totalChunks batch(es)..."

    $chunkIndex = 0
    foreach ( $chunk in $chunks ) {
        $chunkIndex++
        $body = @{ "members@odata.bind" = [array]$chunk }
        # add members
        try { 
            Write-Verbose "Processing batch $chunkIndex/$totalChunks ($($chunk.count) members)..."
            
            if ( -not $WhatIf ) { 
                Invoke-MgGraphRequest -method PATCH -uri "/v1.0/groups/$groupId" -Body $body -OutputType PSObject -StatusCodeVariable statusCode -Verbose:$false
                if ( $statusCode -ne 204 ) { throw "Failed to add members to groupId '$groupId'. Status code: $statusCode" }    
            }
            
            $addedCount += $chunk.count
            Write-Verbose "Batch $chunkIndex/$totalChunks complete."
        }
        catch { 
            if ( $skipMembershipCheck ) { throw "Failed to add members to groupId '$groupId'. This may be due to some members already being in the group. Consider re-running without the -skipMembershipCheck switch. $_" }
            else { throw "Failed to add members to groupId '$groupId'. $_" }
        }
    }

    # Summary
    if ( $WhatIf ) { Write-Host "WhatIf: Would have added $addedCount member(s) to group '$($group.displayName)' ($groupId)..." -ForegroundColor Yellow }
    else { Write-Host "Successfully added $addedCount member(s) to group '$($group.displayName)' ($groupId)..." -ForegroundColor Green }
}