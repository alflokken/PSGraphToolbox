function Find-GtServicePrincipal {
    <#
    .SYNOPSIS
    Search Entra ID service principals (enterprise apps) by displayName, id or appId.

    .DESCRIPTION
    [AI-GENERATED] This function was generated using Claude Opus 4.8.

    Finds service principals by displayName, or by exact object id / appId (GUID), and returns one object per match with:
    - Basic properties (type, enabled, assignment required, home tenant, verified publisher, SSO mode, tags, notes)
    - Owners
    - Users and groups assigned to the enterprise app (appRoleAssignedTo), as display names
    - Granted application permissions (appRoleAssignments) and delegated permissions (oauth2PermissionGrants, admin and user consent combined), as Resource:Permission

    Lookups are scoped to the matched service principals only, using batched requests.
    Permission names are resolved only for the resource APIs actually referenced by the matches.
    For app registration design (redirect URIs, credentials, exposed scopes) see Find-GtApplication.
    Queries the beta endpoint.

    Requires scopes: Application.Read.All, AppRoleAssignment.ReadWrite.All or Directory.Read.All (assignments), DelegatedPermissionGrant.Read.All (delegated grants).
    Optional: AuditLog.Read.All (-IncludeSignInActivity).

    .PARAMETER SearchString
    Search string (3-99 chars). A GUID is matched exactly against id or appId; any other string is a displayName
    search that matches words starting with the string (e.g. 'contoso' matches 'Contoso HR App').

    .PARAMETER AdditionalProperties
    Extra service principal properties to include in results (comma separated, no spaces, e.g. signInAudience,loginUrl).

    .PARAMETER IncludeSignInActivity
    Adds a signInActivity property with the last sign-in timestamp per activity type (lastSignIn, delegatedClientSignInActivity,
    delegatedResourceSignInActivity, applicationAuthenticationClientSignInActivity, applicationAuthenticationResourceSignInActivity).
    Queried per matched appId (batched, beta endpoint). Values are null when no sign-in has been recorded.

    .OUTPUTS
    One PSObject per service principal with:
    id, displayName, appId, createdDateTime, servicePrincipalType, accountEnabled, appRoleAssignmentRequired, appOwnerOrganizationId,
    verifiedPublisher (display name), preferredSingleSignOnMode, tags, notes, any -AdditionalProperties,
    owners (UPN or displayName), assignedUsers, assignedGroups (display names),
    apiPermissionsApplication, apiPermissionsDelegated (Resource:Permission, resource names without spaces)
    and, with -IncludeSignInActivity, signInActivity.

    .EXAMPLE
    Find-GtServicePrincipal "contoso"
    Returns service principals with a word in displayName starting with 'contoso'.

    .EXAMPLE
    Find-GtServicePrincipal "00000003-0000-0000-c000-000000000000"
    Returns the service principal with the given appId (or object id).

    .EXAMPLE
    Find-GtServicePrincipal "contoso" | Select-Object displayName, assignedUsers, assignedGroups
    Shows who has been assigned to matching enterprise apps.

    .EXAMPLE
    Find-GtServicePrincipal "contoso" -IncludeSignInActivity | Select-Object displayName, @{ n = 'lastSignIn'; e = { $_.signInActivity.lastSignIn } }
    Shows when matching enterprise apps last signed in.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/servicePrincipals/Find-GtServicePrincipal.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateLength(3, 99)]
        [String]$SearchString,

        [Parameter(Mandatory = $false)]
        [ValidatePattern("^[a-z0-9,]+$")]
        [String]$AdditionalProperties,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSignInActivity
    )

    $queryParams = @{ resourcePath = "servicePrincipals"; apiVersion = "beta" }
    $queryParams.select = "id,appId,displayName,servicePrincipalType,accountEnabled,appRoleAssignmentRequired,appOwnerOrganizationId,verifiedPublisher,preferredSingleSignOnMode,tags,notes,createdDateTime"
    if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select),$AdditionalProperties" }
    if ( $SearchString | isValidGuid ) { $queryParams.filter = "id eq '$SearchString' or appId eq '$SearchString'" }
    else { $queryParams.search = "`"displayName:$SearchString`"" }

    Write-GtVerbose "Searching service principals with $($queryParams.search) $($queryParams.filter)"
    try { $servicePrincipals = @(Invoke-GtGraphRequest @queryParams -Verbose:$false) }
    catch { throw $_ }
    if ( -not $servicePrincipals ) { return }

    # per service principal lookups (one batch; $expand is not supported alongside $search)
    $requests = @()
    $index = 0
    foreach ( $sp in $servicePrincipals ) {
        $base = "servicePrincipals/$($sp.id)"
        $requests += @{ id = "$index-owners";     method = "GET"; url = "$base/owners?`$select=id,userPrincipalName,displayName" }
        $requests += @{ id = "$index-assignedTo"; method = "GET"; url = "$base/appRoleAssignedTo?`$select=principalType,principalDisplayName&`$top=999" }
        $requests += @{ id = "$index-roles";      method = "GET"; url = "$base/appRoleAssignments?`$select=appRoleId,resourceId,resourceDisplayName&`$top=999" }
        $requests += @{ id = "$index-grants";     method = "GET"; url = "$base/oauth2PermissionGrants?`$select=resourceId,scope" }
        $index++
    }
    Write-GtVerbose "Loading owners, assignments and granted permissions for $($servicePrincipals.Count) service principal(s)"
    $responses = Invoke-GtGraphBatchRequest -Requests $requests -Verbose:$false

    # resolve names only for the resource APIs referenced by the matches (appRoles is only needed for application permissions)
    $roleResourceIds = @{}
    $grantResourceIds = @{}
    for ( $i = 0; $i -lt $servicePrincipals.Count; $i++ ) {
        foreach ( $a in $responses["$i-roles"] ) { if ( $a.resourceId ) { $roleResourceIds[[string]$a.resourceId] = $true } }
        foreach ( $g in $responses["$i-grants"] ) { if ( $g.resourceId ) { $grantResourceIds[[string]$g.resourceId] = $true } }
    }
    $resourceRequests = @()
    foreach ( $resourceId in $roleResourceIds.Keys ) { $resourceRequests += @{ id = $resourceId; method = "GET"; url = "servicePrincipals/${resourceId}?`$select=id,displayName,appRoles" } }
    foreach ( $resourceId in $grantResourceIds.Keys ) {
        if ( -not $roleResourceIds.ContainsKey($resourceId) ) { $resourceRequests += @{ id = $resourceId; method = "GET"; url = "servicePrincipals/${resourceId}?`$select=id,displayName" } }
    }
    $resourcesById = @{}
    if ( $resourceRequests ) {
        Write-GtVerbose "Resolving permission names from $($resourceRequests.Count) resource service principal(s)"
        # a deleted resource (orphaned grant) returns 404, those fall back to the raw id
        $resourcesById = Invoke-GtGraphBatchRequest -Requests $resourceRequests -Verbose:$false -WarningAction SilentlyContinue
    }

    # Sign-in activity (filter is only supported on the beta endpoint, hence a separate batch)
    $signInResponses = @{}
    if ( $IncludeSignInActivity ) {
        $signInRequests = @()
        for ( $i = 0; $i -lt $servicePrincipals.Count; $i++ ) {
            $signInRequests += @{ id = "$i-signIn"; method = "GET"; url = "reports/servicePrincipalSignInActivities?`$filter=appId eq '$($servicePrincipals[$i].appId)'" }
        }
        Write-GtVerbose "Loading sign-in activity for $($servicePrincipals.Count) service principal(s)"
        $signInResponses = Invoke-GtGraphBatchRequest -Requests $signInRequests -ApiVersion beta -Verbose:$false
    }

    $extraProperties = @()
    if ( $AdditionalProperties ) { $extraProperties = $AdditionalProperties -split "," | Where-Object { $_ } }

    $index = 0
    foreach ( $sp in $servicePrincipals ) {

        $owners = @($responses["$index-owners"] | ForEach-Object { if ( $_.userPrincipalName ) { $_.userPrincipalName } else { $_.displayName } })

        $assignedTo = @($responses["$index-assignedTo"])
        $assignedUsers  = @($assignedTo | Where-Object { $_.principalType -eq "User" }  | ForEach-Object { $_.principalDisplayName })
        $assignedGroups = @($assignedTo | Where-Object { $_.principalType -eq "Group" } | ForEach-Object { $_.principalDisplayName })

        $applicationPermissions = @()
        foreach ( $a in $responses["$index-roles"] ) {
            $resource = $resourcesById[[string]$a.resourceId]
            $permission = $a.appRoleId
            foreach ( $role in $resource.appRoles ) { if ( $role.id -eq $a.appRoleId ) { $permission = $role.value; break } }
            $applicationPermissions += "$($a.resourceDisplayName -replace '\s', ''):$permission"
        }

        $delegatedPermissions = @()
        foreach ( $g in $responses["$index-grants"] ) {
            $resourceName = $g.resourceId
            $resource = $resourcesById[[string]$g.resourceId]
            if ( $resource.displayName ) { $resourceName = $resource.displayName -replace '\s', '' }
            foreach ( $scope in ($g.scope -split " " | Where-Object { $_ }) ) { $delegatedPermissions += "${resourceName}:$scope" }
        }

        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -NotePropertyName id                        -NotePropertyValue $sp.id
        $obj | Add-Member -NotePropertyName displayName               -NotePropertyValue $sp.displayName
        $obj | Add-Member -NotePropertyName appId                     -NotePropertyValue $sp.appId
        $obj | Add-Member -NotePropertyName createdDateTime           -NotePropertyValue $sp.createdDateTime
        $obj | Add-Member -NotePropertyName servicePrincipalType      -NotePropertyValue $sp.servicePrincipalType
        $obj | Add-Member -NotePropertyName accountEnabled            -NotePropertyValue $sp.accountEnabled
        $obj | Add-Member -NotePropertyName appRoleAssignmentRequired -NotePropertyValue $sp.appRoleAssignmentRequired
        $obj | Add-Member -NotePropertyName appOwnerOrganizationId    -NotePropertyValue $sp.appOwnerOrganizationId
        $obj | Add-Member -NotePropertyName verifiedPublisher         -NotePropertyValue $sp.verifiedPublisher.displayName
        $obj | Add-Member -NotePropertyName preferredSingleSignOnMode -NotePropertyValue $sp.preferredSingleSignOnMode
        $obj | Add-Member -NotePropertyName tags                      -NotePropertyValue @($sp.tags)
        $obj | Add-Member -NotePropertyName notes                     -NotePropertyValue $sp.notes
        foreach ( $property in $extraProperties ) { $obj | Add-Member -NotePropertyName $property -NotePropertyValue $sp.$property -Force }
        $obj | Add-Member -NotePropertyName owners                    -NotePropertyValue $owners
        $obj | Add-Member -NotePropertyName assignedUsers             -NotePropertyValue $assignedUsers
        $obj | Add-Member -NotePropertyName assignedGroups            -NotePropertyValue $assignedGroups
        $obj | Add-Member -NotePropertyName apiPermissionsApplication -NotePropertyValue @($applicationPermissions | Select-Object -Unique)
        $obj | Add-Member -NotePropertyName apiPermissionsDelegated   -NotePropertyValue @($delegatedPermissions | Select-Object -Unique)
                if ( $IncludeSignInActivity ) {
                    # Flatten each *SignInActivity object to its lastSignInDateTime
                    $activity = @($signInResponses["$index-signIn"]) | Select-Object -First 1
                    $flatSignInActivity = New-Object -TypeName PSObject
                    $flatSignInActivity | Add-Member -NotePropertyName lastSignIn                                      -NotePropertyValue $activity.lastSignInActivity.lastSignInDateTime
                    $flatSignInActivity | Add-Member -NotePropertyName delegatedClientSignInActivity                   -NotePropertyValue $activity.delegatedClientSignInActivity.lastSignInDateTime
                    $flatSignInActivity | Add-Member -NotePropertyName delegatedResourceSignInActivity                 -NotePropertyValue $activity.delegatedResourceSignInActivity.lastSignInDateTime
                    $flatSignInActivity | Add-Member -NotePropertyName applicationAuthenticationClientSignInActivity   -NotePropertyValue $activity.applicationAuthenticationClientSignInActivity.lastSignInDateTime
                    $flatSignInActivity | Add-Member -NotePropertyName applicationAuthenticationResourceSignInActivity -NotePropertyValue $activity.applicationAuthenticationResourceSignInActivity.lastSignInDateTime
                    $obj | Add-Member -NotePropertyName signInActivity -NotePropertyValue $flatSignInActivity
                }
                $obj
        $index++
    }
}
