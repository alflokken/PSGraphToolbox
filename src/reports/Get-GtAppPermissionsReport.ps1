function Get-GtAppPermissionsReport {
    <#
    .SYNOPSIS
    Reports service principal permissions and flags privileged ones.

    .DESCRIPTION
    Lists service principals with app role assignments, delegated grants or directory roles, as an HTML report or raw objects.
    Service principals without any of these are left out.

    Privilege classification:
    - Application permissions and delegated scopes are flagged isPrivileged when listed as High in the Zero Trust Assessment
      consent grant permission table, or when they belong to a High permission family (e.g. Mail.*, Files.*).
      *.Selected and *.ReadBasic* permissions are never flagged.
    - Directory roles use the role definition's isPrivileged flag.
    Delegated grants are expanded to one entry per scope; principalDisplayName is resolved for user consent grants only.

    The HTML report is written to the current directory as PSGraphToolbox_PrivilegedAppPermissionsReport_{timestamp}.html
    and opened in the default browser, with all 'id' and '*Id' properties omitted.

    Requires scopes: Application.Read.All, DelegatedPermissionGrant.Read.All, RoleManagement.Read.Directory, Directory.Read.All.
    Optional: AuditLog.Read.All (-IncludeSignInActivity), CrossTenantInformation.ReadBasic.All (-IncludeAppOwnerOrganization).

    .PARAMETER Raw
    Return enriched objects with all collected properties and IDs retained, without generating HTML.

    .PARAMETER IncludeOwners
    Include owners of the service principals (servicePrincipalOwners) and their applications (applicationRegistrationOwners).
    The properties are only added when owners exist.

    .PARAMETER IncludeSignInActivity
    Include service principal sign-in activity (beta endpoint) as signInActivity, with the last sign-in timestamp per activity type
    (lastSignIn, delegatedClientSignInActivity, delegatedResourceSignInActivity, applicationAuthenticationClientSignInActivity,
    applicationAuthenticationResourceSignInActivity).

    .PARAMETER IncludeAppOwnerOrganization
    Include the owner organization (tenant) of each application as appOwnerOrganization: "Name [defaultDomainName]",
    or the tenant ID if it cannot be resolved.

    .PARAMETER AdditionalServicePrincipalV1SelectProperties
    Additional comma-separated servicePrincipal properties to select (v1.0, no spaces), e.g. appRoleAssignmentRequired,signInAudience.

    .OUTPUTS
    -Raw: array of service principal objects with id, appId, displayName, accountEnabled, appOwnerOrganizationId, servicePrincipalType,
    any additional properties, and:
    - appRoleAssignments (appRoleId, resourceId, resourceDisplayName, principalType, permissionName, isPrivileged)
    - oauth2PermissionGrants (one entry per scope: consentType, principalId, principalDisplayName, resourceId, resourceDisplayName, scope, isPrivileged)
    - assignedRoles (id, displayName, isPrivileged)
    - hasPrivilegedApplicationPermissions, hasPrivilegedDelegatedPermissions, hasPrivilegedRoleAssignments, hasRoleAssignments
    - optional: appOwnerOrganization, servicePrincipalOwners, applicationRegistrationOwners, signInActivity
    Default: nothing is returned; the HTML report is written (see description).

    .EXAMPLE
    Get-GtAppPermissionsReport
    Generates an HTML report of service principal permissions.

    .EXAMPLE
    Get-GtAppPermissionsReport -Raw -IncludeOwners | Where-Object { $_.displayName -like "*Backup*" }
    Returns raw objects including owners and filters them in the pipeline.

    .EXAMPLE
    Get-GtAppPermissionsReport -IncludeSignInActivity -AdditionalServicePrincipalV1SelectProperties "appRoleAssignmentRequired,signInAudience"
    Generates a report with sign-in activity and extra service principal properties.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtAppPermissionsReport.md
    #>
    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $false)]
        [switch]$Raw,
        # 	Enriched objects, all collected properties and IDs retained; no HTML generation
        # default: HTML report, IDs omitted

        [Parameter(Mandatory = $false)]
        [switch]$IncludeOwners,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSignInActivity,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAppOwnerOrganization,
        
        # additional servicePrincipal select properties e.g. appRoleAssignmentRequired,signInAudience
        [Parameter(Mandatory = $false)]
        [ValidatePattern("^[a-z0-9,]+$")]
        [String]$AdditionalServicePrincipalV1SelectProperties
    )
    
    #region graph requests
    Write-GtVerbose 'fetching all servicePrincipals and their app role assignments'
    $spnQueryParams = @{
        resourcePath = 'servicePrincipals'
        select       = "id,appId,displayName,appRoles,accountEnabled,appOwnerOrganizationId,servicePrincipalType" #isDisabled(beta only)
        expand       = 'appRoleAssignments($select=appRoleId,resourceId,resourceDisplayName,principalType)' #principalDisplayName
        pageLimit    = 999
        verbose      = $false
    }
    if ( $AdditionalServicePrincipalV1SelectProperties ) { $spnQueryParams.select = "$($spnQueryParams.select),$AdditionalServicePrincipalV1SelectProperties" }
    $servicePrincipals = Invoke-GtGraphRequest @spnQueryParams
    Write-GtVerbose "retrieved $($servicePrincipals.Count) servicePrincipals"

    # expand query typically returns a maximum of 20 items for the expanded relationship and has no @odata.nextLink
    # resolve service principals with 20 or more app role assignments directly (batched)
    $appRoleAssignmentRequests =  $serviceprincipals | where { $_.appRoleAssignments.count -ge 20 } | ForEach-Object {
        @{ id = $_.id; method = "GET"; url = "servicePrincipals/$($_.id)/appRoleAssignments?`$select=appRoleId,resourceId,resourceDisplayName,principalType" }
    }
    if ( $appRoleAssignmentRequests ) { 
        Write-GtVerbose "resolving app role assignments for service principals with 20 or more assignments"
        $appRoleAssignmentsById = Invoke-GtGraphBatchRequest -Requests $appRoleAssignmentRequests -Verbose:$false 
    }

    Write-GtVerbose 'fetching oauth2 permission grants'
    $oauth2PermissionGrants = Invoke-GtGraphRequest -resourcePath "oauth2PermissionGrants" -select "clientId,consentType,principalId,resourceId,scope" -PageLimit 999 -Verbose:$false

    $uniqueOauth2PrincipalIds = $oauth2PermissionGrants | Where-Object { $_.consentType -eq 'Principal' } | Select-Object -ExpandProperty principalId | Sort-Object -Unique
    Write-GtVerbose "resolving assigned oauth2 principal displayNames"
    if ( $uniqueOauth2PrincipalIds ) {
        $principalsById = Get-GtGraphDirectoryObjectsByIds -Type user -Ids $uniqueOauth2PrincipalIds -Verbose:$false | ConvertTo-HashTable
    }

    Write-GtVerbose 'fetching directory roleDefinitions and roleAssignments'
    try { 
        $roleDefinitionsById = Invoke-GtGraphRequest "roleManagement/directory/roleDefinitions" -Select "id,displayName,isPrivileged" -ApiVersion beta -Verbose:$false | ConvertTo-HashTable -keyProperty "id"
        # a principal can hold multiple role assignments; group (1:many) instead of ConvertTo-HashTable (1:1, last wins)
        $allRoleAssignmentsByPrincipalId = Invoke-GtGraphRequest "roleManagement/directory/roleAssignments" -Select "id,principalId,roleDefinitionId" -Verbose:$false | Group-Object -Property principalId -AsHashTable
        if ( -not $allRoleAssignmentsByPrincipalId ) { $allRoleAssignmentsByPrincipalId = @{} }
    }
    catch { Write-Warning "Get-GtAppPermissionsReport: role assignments unavailable."; $roleDefinitionsById = @{}; $allRoleAssignmentsByPrincipalId = @{} }
    
    # owners
    if ( $IncludeOwners ) {
        Write-GtVerbose 'fetching owners for all service principals and applications'
        try { $ownersByServicePrincipalId = Invoke-GtGraphRequest -resourcePath "servicePrincipals" -select "id" -expand 'owners($select=id,displayName)' -Verbose:$false | ConvertTo-HashTable -keyProperty "id" }
        catch { Write-Warning "Get-GtAppPermissionsReport: owners for service principals unavailable."; $ownersByServicePrincipalId = @{} }
        try { $applicationOwnersByAppId = Invoke-GtGraphRequest -ResourcePath "applications" -select "id,appId" -Expand  'owners($select=id,displayName)' -Verbose:$false | ConvertTo-HashTable -keyProperty "appid" }
        catch { Write-Warning "Get-GtAppPermissionsReport: owners for applications unavailable."; $applicationOwnersByAppId = @{} }
    }
    
    if ( $IncludeSignInActivity ) {
        Write-GtVerbose 'fetching servicePrincipalSignInActivities report'
        try { $servicePrincipalSignInActivitiesByAppId  = Invoke-GtGraphRequest -resourcePath "reports/servicePrincipalSignInActivities" -apiVersion beta -Verbose:$false | ConvertTo-HashTable -keyProperty "appId" }
        catch { Write-Warning "Get-GtAppPermissionsReport: sign-in activity unavailable."; $servicePrincipalSignInActivitiesByAppId  = @{} }
    }
    #endregion graph requests

    #region privilege classification
    # permissions from ZTA: https://github.com/microsoft/zerotrustassessment/blob/main/src/powershell/assets/aadconsentgrantpermissiontable.csv
    $aadConsentGrantPermissionTableJson = '[{"Type":"Delegated","Permission":"Mail.ReadBasic","Privilege":"Medium","Reason":"DataExfiltration"},{"Type":"Delegated","Permission":"Mail","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"Contacts","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"MailboxSettings","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"People","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"Files","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"AllSites","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"Notes","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"Policy","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"AppRoleAssignment.ReadWrite.All","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"Directory.AccessAsUser.All","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"user_impersonation","Privilege":"High","Reason":"Phishing"},{"Type":"Delegated","Permission":"Application.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"Directory.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"Domain.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"EduRoster.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"Group.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"Member.Read.Hidden","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"RoleManagement.ReadWrite.Directory","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"RoleAssignmentSchedule.ReadWrite.Directory","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"RoleEligibilitySchedule.ReadWrite.Directory","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"User.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"User.ManageCreds.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Delegated","Permission":"User.Export.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"Mail","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"Contacts","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"MailboxSettings","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"People","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"Files","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"Sites","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"AllSites","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"Notes","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"Policy","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"PrivilegedAccess","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"PrivilegedAssignmentSchedule","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"PrivilegedEligibilitySchedule","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"AppRoleAssignment.ReadWrite.All","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"Directory.AccessAsUser.All","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"user_impersonation","Privilege":"High","Reason":"Phishing"},{"Type":"Application","Permission":"Application.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"Directory.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"Domain.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"EduRoster.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"Group.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"Member.Read.Hidden","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"UserAuthenticationMethod.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"RoleManagement.ReadWrite.Directory","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"User.ReadWrite.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"User.ManageCreds.All","Privilege":"High","Reason":"BroadImpact"},{"Type":"Application","Permission":"CallRecords.Read.All","Privilege":"High","Reason":"SensitiveData"},{"Type":"Delegated","Permission":"User.Read","Privilege":"Low","Reason":"Common pattern"},{"Type":"Delegated","Permission":"User.ReadBasic.All","Privilege":"Low","Reason":"Common pattern"},{"Type":"Delegated","Permission":"openid","Privilege":"Low","Reason":"Common pattern"},{"Type":"Delegated","Permission":"email","Privilege":"Low","Reason":"Common pattern"},{"Type":"Delegated","Permission":"profile","Privilege":"Low","Reason":"Common pattern"},{"Type":"Delegated","Permission":"offline_access","Privilege":"Low","Reason":"Common pattern when used with other low permissions"}]'
    $permissionTable = $aadConsentGrantPermissionTableJson | ConvertFrom-Json

    # exact lookup: "Type|Permission" -> Privilege
    $privilegeByKey = @{}
    # family entries (no dot, e.g. Mail, Sites) are High and cover Mail.Read, Mail.Send, ...
    $familyNamesByType = @{ Delegated = @(); Application = @() }
    foreach ( $row in $permissionTable ) {
        $privilegeByKey["$($row.Type)|$($row.Permission)"] = $row.Privilege
        if ( $row.Privilege -eq 'High' -and $row.Permission -notlike '*.*' ) { $familyNamesByType[$row.Type] += $row.Permission }
    }
    # one regex per type, e.g. ^(?:Mail|Contacts|Sites|...)\.
    $familyRegexByType = @{}
    foreach ( $type in $familyNamesByType.Keys ) { $familyRegexByType[$type] = '^(?:' + ($familyNamesByType[$type] -join '|') + ')\.' }
    $privilegeCache = @{}

    # returns $true if the permission is privileged; uses lookup tables and cache from the enclosing function
    function isPrivilegedPermission {
        <#
        .SYNOPSIS
        Checks whether a permission is classified as privileged.

        .DESCRIPTION
        Uses the consent grant permission lookup table and result cache from the enclosing function.

        .PARAMETER Type
        Permission type: Application or Delegated.

        .PARAMETER Permission
        The permission name, e.g. Mail.ReadWrite.

        .EXAMPLE
        isPrivilegedPermission -Type Delegated -Permission "Directory.ReadWrite.All"
        Returns $true.
        #>
        param ( [string]$Type, [string]$Permission )
        if ( -not $Permission ) { return $false }
        $key = "$Type|$Permission"
        if ( $privilegeCache.ContainsKey($key) ) { return $privilegeCache[$key] }

        if ( $Permission -like '*.Selected' -or $Permission -like '*.ReadBasic*' ) { $result = $false }
        elseif ( $privilegeByKey.ContainsKey($key) ) { $result = $privilegeByKey[$key] -eq 'High' }
        elseif ( $familyRegexByType.ContainsKey($Type) ) { $result = [bool]($Permission -match $familyRegexByType[$Type]) }
        else { $result = $false }

        $privilegeCache[$key] = $result
        return $result
    }
    #endregion privilege classification

    #region resolve permissions
    # cross-reference: service principals by client and resource
    $servicePrincipalsById = $servicePrincipals | ConvertTo-HashTable

    # cross-reference: app roles by resource ID
    $appRolesByResource = @{}
    foreach ( $servicePrincipal in $servicePrincipals ) {
        $appRolesByResource[$servicePrincipal.id] = $servicePrincipal.appRoles | ConvertTo-HashTable
    }
    # discard appRoles and odata properties from service principals
    $servicePrincipals = $servicePrincipals | Select-Object -Property * -ExcludeProperty appRoles,'*@odata.context'

    # cross-reference: oauth2 permission grants by client ID (grouped by client ID)
    $grantsByClient = @{}
    foreach ( $grant in $oauth2PermissionGrants ) {
        $grant | Add-Member -NotePropertyName clientDisplayName -NotePropertyValue $servicePrincipalsById[$grant.clientId].displayName -Force
        $grant | Add-Member -NotePropertyName resourceDisplayName -NotePropertyValue $servicePrincipalsById[$grant.resourceId].displayName -Force
        # multiple grants on the same client ID grouped to list
        if ( -not $grantsByClient.ContainsKey($grant.clientId) ) { $grantsByClient[$grant.clientId] = @() }
        $grantsByClient[$grant.clientId] += $grant
    }

    # resolve permission names on each app role assignment
    foreach ( $servicePrincipal in $servicePrincipals ) {
        foreach ( $assignment in $servicePrincipal.appRoleAssignments ) {
            $permissionName = $null
            try { $permissionName = $appRolesByResource[$assignment.resourceId][$assignment.appRoleId].value } catch { }
            $assignment | Add-Member -NotePropertyName permissionName -NotePropertyValue $permissionName
        }
    }
    #endregion resolve permissions
    
    #region add permissions and filter servicePrincipals by privilege
    foreach ( $servicePrincipal in $servicePrincipals ) {
        
        # update servicePrincipals array with newly retrieved app role assignments
        if ( $appRoleAssignmentsById[$servicePrincipal.id] ) {
            Write-Debug "Updating app role assignments for service principal $($servicePrincipal.id) had $($servicePrincipal.appRoleAssignments.count) assignments, now has $($appRoleAssignmentsById[$servicePrincipal.id].count) assignments"
            $servicePrincipal.appRoleAssignments = $appRoleAssignmentsById[$servicePrincipal.id]
        }

        # collect assigned roles for the service principal
        $assignedRoles = @()
        foreach ( $roleAssignment in $allRoleAssignmentsByPrincipalId[$servicePrincipal.id] ) { 
            Write-Debug "Processing role assignment for principal ID $($servicePrincipal.id) and role definition ID $($roleAssignment.roleDefinitionId)"
            $roleDefinition = $roleDefinitionsById[$roleAssignment.roleDefinitionId] | Select-Object id, displayName, isPrivileged
            $assignedRoles += $roleDefinition
        }
        $servicePrincipal | Add-Member -NotePropertyName assignedRoles -NotePropertyValue $assignedRoles
        $servicePrincipal | Add-Member -NotePropertyName hasPrivilegedRoleAssignments -NotePropertyValue ([bool]($assignedRoles | Where-Object isPrivileged))
        #TODO:TEMP
        $servicePrincipal | Add-Member -NotePropertyName hasRoleAssignments -NotePropertyValue ([bool]($assignedRoles))
        $servicePrincipal | Add-Member -NotePropertyName oauth2PermissionGrants -NotePropertyValue $grantsByClient[$servicePrincipal.id]
    }
    $servicePrincipals = $servicePrincipals | where-Object { $_.appRoleAssignments.Count -gt 0 -or $_.oauth2PermissionGrants.Count -gt 0 -or $_.assignedRoles.Count -gt 0 }
    Write-GtVerbose "working with $($servicePrincipals.Count) service principals after filtering by privilege"
    #endregion add permissions and filter servicePrincipals by privilege

    #region resolve tenantInformation filtered servicePrincipals
    if ( $IncludeAppOwnerOrganization ) {
        $tenantInformationByOrgId = @{}
        $uniqueOrgIds = $servicePrincipals | ForEach-Object { $_.appOwnerOrganizationId } | Where-Object { $_ } | Sort-Object -Unique
        $OrgIdRequests = $uniqueOrgIds | ForEach-Object {
            @{ id = $_; method = "GET"; url = "tenantRelationships/findTenantInformationByTenantId(tenantId='$($_)')" }
        }
        if ( $OrgIdRequests ) { 
            Write-GtVerbose "resolving appOwnerOrganization information for $($servicePrincipals.Count) service principals from $($uniqueOrgIds.Count) unique organizations"
            # 404 (unknown tenant) warnings are expected; other failures (e.g. 403 without CrossTenantInformation.ReadBasic.All) arrive as errors
            $tenantInformationByOrgId = Invoke-GtGraphBatchRequest -Requests $OrgIdRequests -Verbose:$false -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -ErrorVariable orgErrors
            if ( $orgErrors ) { Write-Warning "Get-GtAppPermissionsReport: appOwnerOrganization unavailable for $(@($orgErrors).Count) of $(@($OrgIdRequests).Count) organization(s): $($orgErrors[0].Exception.Message)" }
        }
    }
    #endregion resolve tenantInformation filtered servicePrincipals

    #region consolidate service principal information
    foreach ( $servicePrincipal in $servicePrincipals ) {

        # enrich service principal with tenant information if requested        
        if ( $IncludeAppOwnerOrganization ) {
            $tenantInformationString = $null
            if ( $servicePrincipal.appOwnerOrganizationId ) {
                $tenantInformation = $tenantInformationByOrgId[[string]$servicePrincipal.appOwnerOrganizationId]
                $tenantInformationString =  if ( $tenantInformation.displayName ) { "$($tenantInformation.displayName) [$($tenantInformation.defaultDomainName)]" } 
                                            else { $servicePrincipal.appOwnerOrganizationId }
            }
            $servicePrincipal | Add-Member -NotePropertyName appOwnerOrganization -NotePropertyValue $tenantInformationString
        }

        # evaluate high privilege status for app role assignments
        foreach ( $assignment in $servicePrincipal.appRoleAssignments ) {
            $isPrivileged = isPrivilegedPermission -Type Application -Permission $assignment.permissionName
            $assignment | Add-Member -NotePropertyName isPrivileged -NotePropertyValue $isPrivileged
        }
        $servicePrincipal | Add-Member -NotePropertyName hasPrivilegedApplicationPermissions -NotePropertyValue ([bool]($servicePrincipal.appRoleAssignments | Where-Object isPrivileged))

        # expand oauth2 permission grants and evaluate high privilege status for each granted scope
        [array]$spnOauth2PermissionGrants = foreach ( $grant in $servicePrincipal.oauth2PermissionGrants ) {
                $principalDisplayName = $null
                if ( $grant.principalId ) {
                    $principalDisplayName = $principalsById[$grant.principalId].displayName
                }
            foreach ( $grantedScope in ($grant.scope -split "\s" | Where-Object { $_ }) ) {
                $scopeEntry = New-Object PSObject
                $scopeEntry | Add-Member -NotePropertyName consentType          -NotePropertyValue $grant.consentType
                $scopeEntry | Add-Member -NotePropertyName principalId          -NotePropertyValue $grant.principalId
                $scopeEntry | Add-Member -NotePropertyName principalDisplayName -NotePropertyValue $principalDisplayName
                $scopeEntry | Add-Member -NotePropertyName resourceId           -NotePropertyValue $grant.resourceId
                $scopeEntry | Add-Member -NotePropertyName resourceDisplayName  -NotePropertyValue $grant.resourceDisplayName
                $scopeEntry | Add-Member -NotePropertyName scope                -NotePropertyValue $grantedScope
                $scopeEntry | Add-Member -NotePropertyName isPrivileged         -NotePropertyValue (isPrivilegedPermission -Type Delegated -Permission $grantedScope)
                $scopeEntry
            }
        }
        $servicePrincipal.oauth2PermissionGrants = $spnOauth2PermissionGrants
        $servicePrincipal | Add-Member -NotePropertyName hasPrivilegedDelegatedPermissions -NotePropertyValue ([bool]($servicePrincipal.oauth2PermissionGrants | Where-Object isPrivileged))

        if ( $IncludeOwners ) { 
            # add servicePrincipalOwners
            if ( $ownersByServicePrincipalId[$servicePrincipal.id].owners) { $servicePrincipal | Add-Member -NotePropertyName servicePrincipalOwners -NotePropertyValue $ownersByServicePrincipalId[$servicePrincipal.id].owners }
            # add applicationRegistrationOwners
            if ( $applicationOwnersByAppId[$servicePrincipal.appId].owners) { $servicePrincipal | Add-Member -NotePropertyName applicationRegistrationOwners -NotePropertyValue $applicationOwnersByAppId[$servicePrincipal.appId].owners }
        }
        if ( $IncludeSignInActivity) {            
            $signInActivity = $servicePrincipalSignInActivitiesByAppId[$servicePrincipal.appId]
            # flatten each *SignInActivity object to its lastSignInDateTime
            $flatSignInActivity = $signInActivity | Select-Object `
                @{ n = 'lastSignIn';                                      e = { $_.lastSignInActivity.lastSignInDateTime } },
                @{ n = 'delegatedClientSignInActivity';                   e = { $_.delegatedClientSignInActivity.lastSignInDateTime } },
                @{ n = 'delegatedResourceSignInActivity';                 e = { $_.delegatedResourceSignInActivity.lastSignInDateTime } },
                @{ n = 'applicationAuthenticationClientSignInActivity';   e = { $_.applicationAuthenticationClientSignInActivity.lastSignInDateTime } },
                @{ n = 'applicationAuthenticationResourceSignInActivity'; e = { $_.applicationAuthenticationResourceSignInActivity.lastSignInDateTime } }
            $servicePrincipal | Add-Member -NotePropertyName signInActivity -NotePropertyValue $flatSignInActivity
        }
    }
    #endregion consolidate service principal information

    #region output
    if ( $Raw ) { return $servicePrincipals }
    function removeObjectIds {
        <#
        .SYNOPSIS
        Returns a copy of an object tree without 'id' / '*Id' properties.

        .PARAMETER Object
        The object, array or value to copy (recursive).

        .EXAMPLE
        removeObjectIds -Object $servicePrincipal
        Returns the service principal without id, appId, resourceId, etc.
        #>
        # [AI-GENERATED] returns a copy of the object tree without 'id' / '*Id' properties
        param([object]$Object)
        if ( $null -eq $Object -or $Object -is [string] -or $Object -is [System.ValueType] ) { return $Object }
        if ( $Object -is [array] ) {
            $items = @()
            foreach ( $element in $Object ) { $items += ,(removeObjectIds -Object $element) }
            return ,$items
        }
        $copy = New-Object PSObject
        foreach ( $property in $Object.PSObject.Properties ) {
            if ( $property.Name -ceq 'id' -or $property.Name -cmatch 'Id$' ) { continue }
            $copy | Add-Member -NotePropertyName $property.Name -NotePropertyValue (removeObjectIds -Object $property.Value)
        }
        return $copy
    }
    $servicePrincipals = @($servicePrincipals | ForEach-Object { removeObjectIds -Object $_ })
    Export-GtHtmlReport -InputObject $servicePrincipals -ReportTitle "App Permissions Report" -TitleProperty "displayName" -Path ".\PSGraphToolbox_PrivilegedAppPermissionsReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    #endregion output
}