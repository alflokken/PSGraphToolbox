function Get-GtDirectoryRoleMemberReport {
    <#
    .SYNOPSIS
    Get all Entra ID directory role assignments and eligibilities with resolved names.

    .DESCRIPTION
    Retrieves both active role assignments and PIM eligible roles from Entra ID.
    Resolves principal displayNames (users, groups, service principals) and role names.
    Optionally includes PIM activation data from audit logs.

    PIM activation data is retrieved from the directory audit logs (category: RoleManagement,
    activityDisplayName: Add member to role completed (PIM activation)). Microsoft retains
    these logs for 30 days by default, so activation history is limited to that window.

    Requires scopes: RoleManagement.Read.Directory, Directory.Read.All.
    For PIM activations: AuditLog.Read.All.

    .PARAMETER IncludePimActivations
    Include PIM activation statistics (last 30 days). Defaults to $true.

    .PARAMETER outputType
    Output format: PSObject or html. Defaults to html.

    .OUTPUTS
    Array of PSObjects (PSObject mode) or HTML report file path (html mode).

    .EXAMPLE
    Get-GtDirectoryRoleMemberReport
    Returns all role members with enriched data as HTML report.

    .EXAMPLE
    Get-GtDirectoryRoleMemberReport -IncludePimActivations:$false -outputType PSObject
    Returns role assignments as PSObject array without PIM activation data.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRoleMemberReport.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$IncludePimActivations = $true,
        
        [Parameter()]
        [ValidateSet("PSObject","html")]
        $outputType = "html"
    )

    # placeholders
    $roles = @()
    $displayNameArray = @()

    Write-Verbose "Retrieving role definition ids and names"
    $roleDefIds = Invoke-GtGraphRequest "roleManagement/directory/roleDefinitions" -select "id,displayName" -Verbose:$false | ConvertTo-HashTable -keyProperty "id"
    $roleDefIds.Add("eb1d8c34-acf5-460d-8424-c1f1a6fbdb85", @{ displayName = "AdHoc License Administrator" })
    $roleDefIds.Add("d24aef57-1500-4070-84db-2666f29cf966", @{ displayName = "Modern Commerce Administrator" })

    Write-Verbose "Retrieving role assignments and eligibilities"
    $roles += Invoke-GtGraphRequest "roleManagement/directory/roleEligibilitySchedules" -select "principalId,roleDefinitionId,memberType" -Verbose:$false | Select-Object *, roleDisplayName, @{N="state";E={"eligible"}}, principalDisplayName, userPrincipalName, lastPimActivationDateTime, @{Name="pimActivationCount";Expression={0}}
    $roles += Invoke-GtGraphRequest "roleManagement/directory/roleAssignments" -select "principalId,roleDefinitionId" -Verbose:$false | Select-Object *, roleDisplayName, @{N="state";E={"active"}}, principalDisplayName, memberType, userPrincipalName, lastPimActivationDateTime, @{Name="pimActivationCount";Expression={0}}

    # resolve principal displayNames by trying to get all types (user, group, servicePrincipal)
    # try users first
    Write-Verbose "Attempting to resolve principal displayNames as users ($(($roles.principalId | Sort-Object -Unique).Count) unique ids)"
    $displayNameArray += Get-GtGraphDirectoryObjectsByIds -type user -ids ($roles.principalId | Sort-Object -Unique) -Verbose:$false | Select-Object id, displayName, @{N="memberType";E={ "user" }}, userPrincipalName
    
    # resolve remaining ids as groupIds
    $remainingIds = $roles.principalId | Where-Object { -not ($displayNameArray.id -contains $_) } | Sort-Object -Unique
    Write-Verbose "Resolving remaining principal ids as groups ($($remainingIds.Count) ids)"
    if ( $remainingIds ) {
        $displayNameArray += Get-GtGraphDirectoryObjectsByIds -type group -ids $remainingIds -Verbose:$false | Select-Object id, displayName, @{N="memberType";E={ "group" }}, userPrincipalName
    }
    
    # resolve servicePrincipals (remaining ids)
    $spnIds = $roles.principalId | Where-Object { -not ($displayNameArray.id -contains $_) } | Sort-Object -Unique
    Write-Verbose "Resolving remaining principal ids as service principals ($($spnIds.Count) ids)"
    if ( $spnIds ) {
        $spnRequests = @()
        foreach ( $spnId in $spnIds ) {
            $spnRequests += @{
                id = $spnId
                method = "GET"
                url = "servicePrincipals/$($spnId)?`$select=id,displayName"
            }
        }
        $spnDisplayNames = Invoke-GtGraphBatchRequest -requests $spnRequests -Verbose:$false
        $displayNameArray += $spnDisplayNames.GetEnumerator() | Select-Object -ExpandProperty value | Select-Object id, displayName, @{N="memberType";E={ "servicePrincipal" }}, userPrincipalName
    }

    # finalize displayName hashtable
    $displayNameHt = $displayNameArray | ConvertTo-HashTable -keyProperty "id"

    # enrich role metadata
    foreach ( $role in $roles ) {
        $role.roleDisplayName = $roleDefIds[$role.roleDefinitionId].displayName
        $role.principalDisplayName = $displayNameHt[$role.principalId].displayName
        $role.memberType = $displayNameHt[$role.principalId].memberType
        $role.userPrincipalName = $displayNameHt[$role.principalId].userPrincipalName
    }

    # expand group memberships
    # cache group members to avoid duplicate API calls when same group has multiple role assignments
    $groups = $roles | Where-Object { $_.memberType -eq "group" }
    $uniqueGroupIds = $groups.principalId | Sort-Object -Unique
    Write-Verbose "Expanding group memberships for $($groups.Count) role assignments ($($uniqueGroupIds.Count) unique groups)"
    
    $groupMembersCache = @{}
    foreach ( $groupId in $uniqueGroupIds ) {
        $groupName = $displayNameHt[$groupId].displayName
        Write-Verbose "Fetching members for group: $groupName"
        $groupMembersCache[$groupId] = Invoke-GtGraphRequest -resourcePath "groups/$groupId/members" -select "id,userPrincipalName,displayName" -Verbose:$false
    }
    
    # expand using cached members
    foreach ( $group in $groups ) {
        $groupMembers = $groupMembersCache[$group.principalId]
        foreach ( $member in $groupMembers ) {
            $obj = New-Object -TypeName PSObject
            $obj | Add-Member -NotePropertyName principalId -NotePropertyValue $member.id
            $obj | Add-Member -NotePropertyName roleDefinitionId -NotePropertyValue $group.roleDefinitionId
            $obj | Add-Member -NotePropertyName roleDisplayName -NotePropertyValue $group.roleDisplayName
            $obj | Add-Member -NotePropertyName state -NotePropertyValue $group.state
            $obj | Add-Member -NotePropertyName principalDisplayName -NotePropertyValue $member.displayName
            $obj | Add-Member -NotePropertyName userPrincipalName -NotePropertyValue $member.userPrincipalName
            $obj | Add-Member -NotePropertyName memberType -NotePropertyValue "user (via group: $($group.principalDisplayName))"
            $obj | Add-Member -NotePropertyName lastPimActivationDateTime -NotePropertyValue $null
            $obj | Add-Member -NotePropertyName pimActivationCount -NotePropertyValue 0
            $roles += $obj
        }
    }

    # exclude original group entries
    $roles = $roles | Where-Object { $_.memberType -ne "group" }

    # enrich eligible roles with PIM activation data
    if ( $IncludePimActivations ) {
        $eligibleRoles = $roles | Where-Object { $_.state -eq "eligible" }

        if ( $eligibleRoles ) {
            Write-Verbose "Retrieving PIM activation audit logs for the last 30 days"
            $pimActivations = Get-GtAuditLogsPimActivations -startDate (Get-Date).AddDays(-30) -Verbose:$false

            if ( $pimActivations ) {
                Write-Verbose "Enriching eligible roles with PIM activation data"
                # Group by principalId_roleDefinitionId
                $pimActivationsHt = @{}; $pimActivations | Group-Object { "$($_.principalId)_$($_.roleId)" } | ForEach-Object { $pimActivationsHt[$_.Name] = $_.Group }
                # Enrich eligible roles
                foreach ( $role in $eligibleRoles ) {
                    Write-Debug "Enriching role: $($role.principalDisplayName) - $($role.roleDisplayName)"
                    $key = "$($role.principalId)_$($role.roleDefinitionId)"
                    if ( $pimActivationsHt.ContainsKey($key) ) {
                        $role.lastPimActivationDateTime = $pimActivationsHt[$key][0].activityDateTime
                        $role.pimActivationCount = $pimActivationsHt[$key].Count
                    }
                }
            }
        }
        else { Write-Warning "No eligible roles found, skipping PIM activation enrichment" }
    }

    # final output
    if ( $IncludePimActivations -eq $false ) { $roles = $roles | Select-Object * -ExcludeProperty lastPimActivationDateTime, pimActivationCount }
    if ( $outputType -eq "html" ) { 
        $roles = $roles | Select-Object principalDisplayName,* -ExcludeProperty principalId, roleDefinitionId -ErrorAction SilentlyContinue
        $roles | Group-Object -Property roleDisplayName | Export-GtHtmlReport -ReportTitle "Entra ID Role Summary" -path ".\PSGraphToolbox_DirectoryRoles_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $roles }
}