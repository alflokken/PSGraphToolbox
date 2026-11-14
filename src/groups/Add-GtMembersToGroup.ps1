function Add-GtMembersToGroup {
    <#
    .SYNOPSIS
    Adds one or more members to an Entra ID (Azure AD) group with batching, duplicate, and membership checks.

    .DESCRIPTION
    Adds one or more members to a Microsoft Entra ID group. Group and Members must be object IDs (GUIDs) or objects with an id property (for example, output from Find-GtGroup or Get-GtUser). Display names and UPNs are not accepted; look up the object first. Removes duplicate member IDs and, unless -skipMembershipCheck is used, skips members that are already direct user members of the group. Members are added in chunks of 20 per PATCH request (members@odata.bind). Writes a summary message to the host and supports -WhatIf for dry-run preview. Throws on errors and warns for non-fatal issues (e.g., already a member).

    The membership check only covers user members: adding a group, device or service principal that is already a member makes the request fail.

    Requires scopes: GroupMember.ReadWrite.All

    .PARAMETER Group
    Group object (any object with an id property) or group object ID (GUID). Aliases: id, groupId.

    .PARAMETER Members
    Array of member objects (any objects with an id property) or member object IDs (GUIDs) to add. Alias: memberIds.

    .PARAMETER skipMembershipCheck
    If specified, skips checking for existing group membership. The request fails if any member is already present.

    .PARAMETER WhatIf
    Preview changes without making them (input validation and the membership check still run).

    .EXAMPLE
    Add-GtMembersToGroup -Group "00000000-0000-0000-0000-000000000000" -Members @("11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222")
    Adds two users, identified by object ID, to the group. Members already in the group are skipped.

    .EXAMPLE
    $group = Find-GtGroup "Sales Team" | Select-Object -First 1
    $user = Get-GtUser "user1@zavainc.com"
    Add-GtMembersToGroup -Group $group -Members $user -WhatIf
    Shows what would be added using group and user objects (their id property is used) without making changes.

    .EXAMPLE
    Add-GtMembersToGroup -Group "00000000-0000-0000-0000-000000000000" -Members "11111111-1111-1111-1111-111111111111" -skipMembershipCheck
    Attempts to add a user to a group without checking if they are already a member.

    .OUTPUTS
    None. Progress and results are written to the host.

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
    $groupId = Get-IdFromInputObject -inputObject $Group -objectIdOnly | Select-Object -ExpandProperty id

    # resolve group displayName 
    if ( $group.PSObject.Properties.Name -notcontains "displayName" ) {
        try { $group = Invoke-GtGraphRequest -resourcePath "groups/$groupId" -select "id,displayName" -Verbose:$false }
        catch { throw "Failed to retrieve group details for groupId '$groupId'. $_" }
    }

    # members validation
    $memberIds = foreach ( $member in $Members ) { Get-IdFromInputObject -inputObject $member -objectIdOnly | Select-Object -ExpandProperty id }

    # members - check for duplicates
    $originalCount = $memberIds.count
    $memberIds = $memberIds | Select-Object -Unique
    if ( $memberIds.count -lt $originalCount ) { write-warning "Duplicate member IDs found. Removed $($originalCount - $memberIds.count) duplicates." }

    if ( -not $skipMembershipCheck ) {
        # identify existing groupMembers - these must be skipped (as Graph API will error if adding existing members, even in batch)
        Write-GtVerbose "Retrieving existing members of group '$($group.displayName)' ($groupId)..." 
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
        Write-GtVerbose "Skipping membership check."
        $membersToAdd = $memberIds
    }

    # split into chunks of 20 (Graph API batch limit)
    $chunks = Split-ArrayIntoChunks -Enumerable ($membersToAdd | %{ "https://graph.microsoft.com/v1.0/directoryObjects/" + $_ }) -ChunkSize 20
    $totalChunks = @($chunks).Count
    $addedCount = 0

    Write-GtVerbose "Adding $($membersToAdd.Count) members in $totalChunks batch(es)..."

    $chunkIndex = 0
    foreach ( $chunk in $chunks ) {
        $chunkIndex++
        $body = @{ "members@odata.bind" = [array]$chunk }
        # add members
        try { 
            Write-GtVerbose "Processing batch $chunkIndex/$totalChunks ($($chunk.count) members)..."
            
            if ( -not $WhatIf ) { 
                Invoke-MgGraphRequest -method PATCH -uri "/v1.0/groups/$groupId" -Body $body -OutputType PSObject -StatusCodeVariable statusCode -Verbose:$false
                if ( $statusCode -ne 204 ) { throw "Failed to add members to groupId '$groupId'. Status code: $statusCode" }    
            }
            
            $addedCount += $chunk.count
            Write-GtVerbose "Batch $chunkIndex/$totalChunks complete."
        }
        catch { 
            if ( $skipMembershipCheck ) { throw "Failed to add members to groupId '$groupId'. This may be due to some members already being in the group. Consider re-running without the -skipMembershipCheck switch. $_" }
            else { throw "Failed to add members to groupId '$groupId'. $_" }
        }
    }

    # Summary
    if ( $WhatIf ) { 
        Write-Host "WhatIf: Would have added $addedCount member(s) to group '$($group.displayName)' ($groupId)..." -ForegroundColor Yellow 
        $membersToAdd | ForEach-Object { Write-Debug "Would add member: $_" }
    }
    else { Write-Host "Successfully added $addedCount member(s) to group '$($group.displayName)' ($groupId)..." -ForegroundColor Green }
}