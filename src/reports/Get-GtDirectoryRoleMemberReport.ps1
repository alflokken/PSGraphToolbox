function Get-GtDirectoryRoleMemberReport {
    <#
    .SYNOPSIS
    Get all Entra ID directory role assignments and eligibilities with resolved names.

    .DESCRIPTION
    Retrieves both active role assignments and PIM eligible roles from Entra ID.
    Resolves principal displayNames (users, groups, service principals) and role names.
    Group assignments are expanded into the group's direct members (not nested groups), and the group entries are removed from the output.
    Use -SkipGroupExpansion to keep the group entries as they are instead.
    Optionally includes PIM activation data from audit logs.

    state is one of:
    - active: activated through PIM (startDateTime/endDateTime from the activation)
    - active (permanent): active assignment without a current PIM activation
    - eligible: time-bound eligibility
    - eligible (permanent): eligibility without an end date

    PIM activation data is retrieved from the directory audit logs (category: RoleManagement,
    activityDisplayName: Add member to role completed (PIM activation)). Microsoft retains
    these logs for 30 days by default, so activation history is limited to that window.

    Requires scopes: RoleManagement.Read.Directory, Directory.Read.All.
    Optional: AuditLog.Read.All (-IncludePimActivations).

    .PARAMETER IncludePimActivations
    Adds recentPimActivations (number of PIM activations in the last 30 days) to eligible entries. Switch parameter, off by default;
    without it the property is omitted.

    .PARAMETER SkipGroupExpansion
    Keeps group assignments as group entries (memberType 'group') instead of expanding them into their members. Switch parameter, off by default.
    No group membership requests are made. For group entries recentPimActivations is empty, as activations are logged for the activating user, not the group.

    .PARAMETER OutputType
    Output format: PSObject or html. Defaults to html.

    .OUTPUTS
    PSObject mode: array of role member objects with principalId, roleDefinitionId, roleDisplayName, directoryScopeId ('/' for tenant-wide, otherwise e.g. an administrative unit; in html mode only shown when some assignment is scoped), principalDisplayName,
    memberType (user, servicePrincipal, group, ... or 'user (via group: <group name>)'), userPrincipalName, startDateTime, endDateTime,
    state and, with -IncludePimActivations, recentPimActivations. With -SkipGroupExpansion, group assignments are returned as memberType 'group'.
    html mode: nothing is returned. Entries (without principalId and roleDefinitionId) are grouped by role and written to
    .\PSGraphToolbox_DirectoryRoles_<yyyyMMdd_HHmmss>.html in the current directory, which is opened in the default browser.

    .EXAMPLE
    Get-GtDirectoryRoleMemberReport
    Returns all role members with enriched data as HTML report, without PIM activation data.

    .EXAMPLE
    Get-GtDirectoryRoleMemberReport -OutputType PSObject
    Returns role assignments as PSObject array without PIM activation data.

    .EXAMPLE
    Get-GtDirectoryRoleMemberReport -IncludePimActivations -OutputType PSObject | Where-Object { $_.state -like "eligible*" -and $_.recentPimActivations -eq 0 }
    Returns eligible role members that have not activated their role in the last 30 days.

    .EXAMPLE
    Get-GtDirectoryRoleMemberReport -SkipGroupExpansion -OutputType PSObject | Where-Object { $_.memberType -eq "group" }
    Returns the groups that hold a directory role, without expanding them into their members.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRoleMemberReport.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludePimActivations,

        [Parameter(Mandatory = $false)]
        [switch]$SkipGroupExpansion,
        
        [Parameter()]
        [ValidateSet("PSObject","html")]
        $OutputType = "html"
    )
    #region graph requests
    Write-GtVerbose "Retrieving role definition ids and names"
    $roleDefinitionsById = Invoke-GtGraphRequest "roleManagement/directory/roleDefinitions" -select "id,displayName" -Verbose:$false | ConvertTo-HashTable -keyProperty "id"
    try { $roleDefinitionsById.Add("eb1d8c34-acf5-460d-8424-c1f1a6fbdb85", @{ displayName = "AdHoc License Administrator" }) } catch {}
    try { $roleDefinitionsById.Add("d24aef57-1500-4070-84db-2666f29cf966", @{ displayName = "Modern Commerce Administrator" }) } catch {}
    try { $roleDefinitionsById.Add("00cf5c54-4693-4f59-a0ac-ab79ef0a974d", @{ displayName = "Microsoft 365 Support Engineer" }) } catch {}
    Write-GtVerbose "Retrieving active role assignments"
    $activeAssignments = Invoke-GtGraphRequest "roleManagement/directory/roleAssignments" -select "principalId,roleDefinitionId,directoryScopeId" -Verbose:$false `
        | Select-Object *, roleDisplayName, principalDisplayName, memberType, userPrincipalName, startDateTime, endDateTime,
            @{N="state";E={"active"}}, 
            @{N="recentPimActivations";E={0}}

    Write-GtVerbose "Retrieving role eligibility assignments"
    $eligibleAssignments = Invoke-GtGraphRequest "roleManagement/directory/roleEligibilitySchedules" -select "principalId,roleDefinitionId,directoryScopeId,memberType,scheduleInfo" -Verbose:$false |
        Select-Object *, roleDisplayName, principalDisplayName, userPrincipalName,
            @{N="state"; E={ if ($_.scheduleInfo.expiration.endDateTime) { "eligible" } else { "eligible (permanent)" } }},
            @{N="startDateTime"; E={ $_.scheduleInfo.startDateTime }},
            @{N="endDateTime";   E={ $_.scheduleInfo.expiration.endDateTime }},
            @{N="recentPimActivations"; E={ 0 }} `
            -ExcludeProperty scheduleInfo

    Write-GtVerbose "Retrieving role assignment schedule instances"
    $scheduleInstances = Invoke-GtGraphRequest "/roleManagement/directory/roleAssignmentScheduleInstances" -Filter "assignmentType eq 'Activated'" -select "principalId,roleDefinitionId,directoryScopeId,startDateTime,endDateTime" -Verbose:$false
    #endregion graph requests

    Write-GtVerbose "Populating active assignments with start/end dates from schedule instances"
    foreach ( $assignment in $activeAssignments ) {
        $scheduleInstance = $scheduleInstances | Where-Object { $_.principalId -eq $assignment.principalId -and $_.roleDefinitionId -eq $assignment.roleDefinitionId -and $_.directoryScopeId -eq $assignment.directoryScopeId }
        if ( $scheduleInstance ) {
            $assignment.startDateTime = $scheduleInstance.startDateTime
            $assignment.endDateTime = $scheduleInstance.endDateTime
        }
        else { $assignment.state = "active (permanent)" }
    }

    # combine eligible and active assignments into a single collection for processing
    $roles = @($eligibleAssignments) + @($activeAssignments)

    # resolve principal displayNames for all roles
    $principalsById = Get-GtGraphDirectoryObjectsByIds -Type directoryObject -Ids ($roles.principalId | Sort-Object -Unique) | ConvertTo-Hashtable

    # enrich role metadata
    foreach ( $role in $roles ) {
        $role.roleDisplayName = $roleDefinitionsById[$role.roleDefinitionId].displayName
        $role.principalDisplayName = $principalsById[$role.principalId].displayName
        $role.memberType = $principalsById[$role.principalId].'@odata.type' -replace '#microsoft.graph.'
        $role.userPrincipalName = $principalsById[$role.principalId].userPrincipalName
        if ( $role.startDateTime ) { $role.startDateTime = $role.startDateTime.ToLocalTime() }
        if ( $role.endDateTime ) { $role.endDateTime = $role.endDateTime.ToLocalTime() }
    }

    if ( $SkipGroupExpansion ) { Write-GtVerbose "Skipping group expansion, group assignments are kept as-is" }
    else {
        # expand group memberships
        # cache group members to avoid duplicate API calls when same group has multiple role assignments
        $groups = $roles | Where-Object { $_.memberType -eq "group" }
        $uniqueGroupIds = $groups.principalId | Sort-Object -Unique
        Write-GtVerbose "Expanding group memberships for $($groups.Count) role assignments ($($uniqueGroupIds.Count) unique groups)"

        $groupMembersById = @{}
        foreach ( $groupId in $uniqueGroupIds ) {
            $groupName = $principalsById[$groupId].displayName
            Write-Debug "Fetching members for group: $groupName"
            $groupMembersById[$groupId] = Invoke-GtGraphRequest -resourcePath "groups/$groupId/members" -select "id,userPrincipalName,displayName" -Verbose:$false
        }
        # expand each member from groups
        foreach ( $group in $groups ) {
            $groupMembers = $groupMembersById[$group.principalId]
            foreach ( $member in $groupMembers ) {
                $expandedMember = New-Object -TypeName PSObject
                $expandedMember | Add-Member -NotePropertyName principalId -NotePropertyValue $member.id
                $expandedMember | Add-Member -NotePropertyName roleDefinitionId -NotePropertyValue $group.roleDefinitionId
                $expandedMember | Add-Member -NotePropertyName roleDisplayName -NotePropertyValue $group.roleDisplayName
                $expandedMember | Add-Member -NotePropertyName directoryScopeId -NotePropertyValue $group.directoryScopeId
                $expandedMember | Add-Member -NotePropertyName state -NotePropertyValue $group.state
                $expandedMember | Add-Member -NotePropertyName principalDisplayName -NotePropertyValue $member.displayName
                $expandedMember | Add-Member -NotePropertyName userPrincipalName -NotePropertyValue $member.userPrincipalName
                $expandedMember | Add-Member -NotePropertyName memberType -NotePropertyValue "user (via group: $($group.principalDisplayName))"
                $expandedMember | Add-Member -NotePropertyName recentPimActivations -NotePropertyValue 0
                $roles += $expandedMember
            }
        }
        # exclude original group entries
        $roles = $roles | Where-Object { $_.memberType -ne "group" }
    }

    # enrich eligible roles with PIM activation data
    if ( $IncludePimActivations ) {
        # -like matches both "eligible" and "eligible (permanent)" states
        $eligibleRoles = $roles | Where-Object { $_.state -like "eligible*" }

        if ( $eligibleRoles ) {
            Write-GtVerbose "Retrieving PIM activation audit logs for the last 30 days"
            $pimActivations = Get-GtAuditLogsPimActivations -startDate (Get-Date).AddDays(-30) -Verbose:$false

            if ( $pimActivations ) {
                Write-GtVerbose "Enriching eligible roles with PIM activation data"
                # group activations by "principalId_roleId" so each eligible role can be matched
                $pimActivationsByKey = @{}; $pimActivations | Group-Object { "$($_.principalId)_$($_.roleId)" } | ForEach-Object { $pimActivationsByKey[$_.Name] = $_.Group }
                # enrich eligible roles
                foreach ( $role in $eligibleRoles ) {
                    Write-Debug "Enriching role: $($role.principalDisplayName) - $($role.roleDisplayName)"
                    $principalRoleKey = "$($role.principalId)_$($role.roleDefinitionId)"
                    if ( $pimActivationsByKey.ContainsKey($principalRoleKey) ) { $role.recentPimActivations = $pimActivationsByKey[$principalRoleKey].Count }
                }
            }
            # activations are logged for the activating user, not the group, so the count is not applicable to group entries
            foreach ( $role in ($eligibleRoles | Where-Object { $_.memberType -eq "group" }) ) { $role.recentPimActivations = $null }
        }
        else { Write-Warning "No eligible roles found, skipping PIM activation enrichment" }
    }

    # final output
    if ( $IncludePimActivations -eq $false ) { $roles = $roles | Select-Object * -ExcludeProperty recentPimActivations }
    if ( $OutputType -eq "html" ) { 
        $exclude = @("principalId", "roleDefinitionId")
        # only show the scope column when at least one assignment is scoped (e.g. to an administrative unit)
        if ( -not ($roles | Where-Object { $_.directoryScopeId -and $_.directoryScopeId -ne "/" }) ) { $exclude += "directoryScopeId" }
        $roles = $roles | Select-Object principalDisplayName,* -ExcludeProperty $exclude -ErrorAction SilentlyContinue
        $roles | Group-Object -Property roleDisplayName | Export-GtHtmlReport -ReportTitle "Entra ID Role Summary" -path ".\PSGraphToolbox_DirectoryRoles_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $roles }
}