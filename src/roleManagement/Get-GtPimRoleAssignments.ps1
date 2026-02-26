function Get-GtPimRoleAssignments {
    <#
    .SYNOPSIS
    Gets PIM role assignments (active and/or eligible) for a user.

    .DESCRIPTION
    Retrieves Privileged Identity Management (PIM) directory role assignments
    for the specified user or the current signed-in user. Can retrieve active
    assignments, eligible assignments, or both.
    
    Requires scopes: RoleEligibilitySchedule.Read.Directory, RoleAssignmentSchedule.Read.Directory, User.Read.All

    .PARAMETER Principal
    The user to retrieve roles for. Accepts a user object, GUID, or userPrincipalName.
    If not specified, retrieves roles for the current signed-in user.

    .PARAMETER State
    Filter by assignment state. Valid values: All, Active, Eligible.
    Default: All (returns both active and eligible assignments).

    .OUTPUTS
    Array of role assignment objects with properties: principalId, userPrincipalName, roleName, roleId, memberType, state, scheduleInfo.

    .EXAMPLE
    Get-GtPimRoleAssignments
    # Returns all role assignments (active and eligible) for the current user

    .EXAMPLE
    Get-GtPimRoleAssignments -State Eligible
    # Returns only eligible roles for the current user
    
    .EXAMPLE
    Get-GtPimRoleAssignments -Principal "admin@zavainc.com" -State Active
    # Returns only active roles for a specific user
    
    .EXAMPLE
    $user | Get-GtPimRoleAssignments
    # Pipeline input with user object

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Get-GtPimRoleAssignments.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [Object]$Principal,

        [Parameter()]
        [ValidateSet("All", "Active", "Eligible")]
        [string]$State = "All"
    )

    if (-not (Get-MgContext)) { throw "No Microsoft Graph context found. Please connect using Connect-MgGraph." }

    # Resolve principal to id and userPrincipalName
    if ($Principal) { $principalId = Get-IdFromInputObject -inputObject $Principal | Select-Object -ExpandProperty id }
    else { $principalId = Get-MgContext | Select-Object -ExpandProperty Account }

    $resolvedPrincipal = Invoke-GtGraphRequest -resourcePath "users/$principalId" -Select "id,userPrincipalName" -Verbose:$false

    # Define queries based on requested state
    $queries = @()
    if ($State -eq "All" -or $State -eq "Eligible") {
        $queries += @{
            State        = "eligible"
            ResourcePath = "roleManagement/directory/roleEligibilitySchedules"
            Select       = "status,principalId,memberType,scheduleInfo"
        }
    }
    if ($State -eq "All" -or $State -eq "Active") {
        $queries += @{
            State        = "active"
            ResourcePath = "roleManagement/directory/roleAssignmentSchedules"
            Select       = "status,principalId,memberType,scheduleInfo,assignmentType"
        }
    }

    $roles = @()
    foreach ($query in $queries) {
        Write-Verbose "Retrieving $($query.State) role assignments for $($resolvedPrincipal.userPrincipalName)"
        $requestParams = @{
            resourcePath = $query.ResourcePath
            filter       = "principalId eq '$($resolvedPrincipal.id)'"
            expand       = "roleDefinition"
            Select       = $query.Select
            Verbose      = $false
        }
        try {
            $queryState = $query.State
            $results = Invoke-GtGraphRequest @requestParams
            $roles += $results | Select-Object `
                principalId,
                @{Name = "userPrincipalName"; Expression = { $resolvedPrincipal.userPrincipalName }},
                @{Name = "roleDisplayName";   Expression = { $_.roleDefinition.displayName }},
                @{Name = "roleId";            Expression = { $_.roleDefinition.id }},
                @{Name = "state";             Expression = { $queryState }},
                @{Name = "scheduleEnd";       Expression = { 
                    if ($_.scheduleInfo.expiration.type -eq "noExpiration") { "NoExpiration" }
                    else { $_.scheduleInfo.expiration.endDateTime } 
                }},
                Status,
                @{Name = "MemberType"; Expression = { 
                    if ($_.assignmentType) { $_.assignmentType } else { $_.memberType }
                }}
        }
        catch { throw $_ }
    }

    return $roles
}