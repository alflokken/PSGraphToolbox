
function Get-GtConditionalAccessPolicyReport {
    <#
    .SYNOPSIS
    Get Conditional Access Policies with resolved friendly names.

    .DESCRIPTION
    Retrieves all Conditional Access policies (beta endpoint) and resolves GUIDs in the policy conditions to human-readable names:
    - Users (as userPrincipalName), groups and directory roles
    - Applications and client service principals
    - Named locations (including "Multifactor authentication trusted IPs")
    IDs that cannot be resolved are kept as-is.

    Well-known Microsoft application names are resolved from a public list downloaded from GitHub
    (merill/microsoft-info, MicrosoftApps.json, 3-second timeout), so internet access is needed; if the download fails,
    errors are written and those applications may be shown by appId. Other (tenant-specific) applications are resolved
    with batch queries.

    Requires scopes: Policy.Read.All, Directory.Read.All.

    .PARAMETER outputType
    Output format: PSObject or html. Defaults to html.

    .PARAMETER onlyEnabledPolicies
    Only return policies with state "enabled" (report-only and disabled policies are excluded).

    .OUTPUTS
    PSObject mode: array of policy objects as returned by Graph, with the resolved names in place of GUIDs in conditions.
    html mode: nothing is returned. The report is written to .\PSGraphToolbox_ConditionalAccessPolicies_<yyyyMMdd_HHmmss>.html
    in the current directory and opened in the default browser.

    .EXAMPLE
    Get-GtConditionalAccessPolicyReport

    Generates HTML report of all CA policies.

    .EXAMPLE
    Get-GtConditionalAccessPolicyReport -onlyEnabledPolicies -outputType PSObject

    Returns only enabled policies as PowerShell objects.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtConditionalAccessPolicyReport.md
    #>
    param(       
        [Parameter()]
        [ValidateSet("PSObject","html")]
        $outputType = "html",
        
        [Parameter()]
        [switch]$onlyEnabledPolicies
    )

    try { 
        $caPolicies = Invoke-GtGraphRequest -resourcePath "identity/conditionalAccess/policies" -apiVersion beta # requires scope: Policy.Read.All
        if ( $onlyEnabledPolicies ) { $caPolicies = $caPolicies | ? State -eq "Enabled" }
    }
    catch { throw $_ }

    # Set-StrictMode -Off # properties like conditions.platforms.includePlatforms are not always present

    # resolve unique group ids (GUID)
    [array]$groupIds = @($caPolicies.conditions.users.includeGroups) + @($caPolicies.conditions.users.excludeGroups) | Sort-Object -Unique | Where-Object { isValidGuid $_ }   
    if ( $groupIds ) { $groupIdCollection = Get-GtGraphDirectoryObjectsByIds -ids $groupIds -type group | ConvertTo-HashTable -keyProperty id }

    # resolve unique user ids (GUID)
    [array]$userIds = @($caPolicies.conditions.users.includeUsers) + @($caPolicies.conditions.users.excludeUsers) | Sort-Object -Unique  | Where-Object { isValidGuid $_}
    if ( $userIds ) { $userIdCollection = Get-GtGraphDirectoryObjectsByIds -ids $userIds -type user | ConvertTo-HashTable -keyProperty id }

    # resolve roleIds (use directoryRoleTemplates to get all roles, not just activated ones)
    if ( $caPolicies.conditions.users.includeRoles -or $caPolicies.conditions.users.excludeRoles ) { 
        $roleTemplates = Invoke-GtGraphRequest -resourcePath "directoryRoleTemplates" -select "id,displayName" 
    }
    
    # resolve namedlocations
    if ( ($caPolicies.conditions.locations.includeLocations | Where-Object { $_ -ne "All" }) -or ($caPolicies.conditions.locations.excludeLocations | Where-Object { $_ -ne "All" }) ) { 
        [array]$namedLocations = Invoke-GtGraphRequest -resourcePath "identity/conditionalAccess/namedLocations" -select "id,displayName"
        $namedLocations += (New-Object -TypeName PSObject -Property @{ id = "00000000-0000-0000-0000-000000000000"; displayName = "Multifactor authentication trusted IPs" })
        $namedLocationCollection = $namedLocations | ConvertTo-HashTable -keyProperty id
    }

    # applications
    $applications = @($caPolicies.conditions.applications.includeApplications) + @($caPolicies.conditions.applications.excludeApplications) | Sort-Object -Unique
    
    # build tenantAppCollection hashTable
    if ( $applications ) {
        
        # initialize collections
        $tenantAppCollection = @{}
        $unknownApps = @()
        
        # resolve wellKnown application from aka.ms/AppNames
        $wellKnownApplicationsBlob = (Invoke-RestMethod "https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.json" -TimeoutSec 3) `
            | Select-Object AppId, AppDisplayName `
            | ConvertTo-HashTable -keyProperty appId

        # cross-reference known and public applications
        foreach ( $id in $applications ) {
            if ( -not (isValidGuid $id) ) { $tenantAppCollection[$id] = $id } 
            elseif ( $wellKnownApplicationsBlob[$id] ) { $tenantAppCollection[$id] = $wellKnownApplicationsBlob[$id].AppDisplayName }
            else { $unknownApps += $id }
        }

        if ( $unknownApps ) {
            # resolve private (unknown) SPNs with batch query
            $spnDisplayNames = Invoke-GtGraphBatchRequest -requests ($unknownApps | ForEach-Object {
                @{
                    id = $_
                    method = "GET"
                    url = "servicePrincipals?`$filter=appId eq '$_'&`$select=displayName"
                }
            })
            # cross-reference apps
            foreach ( $id in $unknownApps ) {
                $appDisplayName = $spnDisplayNames[$id].displayName
                if ( $appDisplayName ) { $tenantAppCollection[$id] = $appDisplayName }
                else { $tenantAppCollection[$id] = $id }
            }
        }
    }

    # service principals
    if ($caPolicies.conditions.clientApplications.includeServicePrincipals -or $caPolicies.conditions.clientApplications.excludeServicePrincipals) {
        [array]$spnIds = @($caPolicies.conditions.clientApplications.includeServicePrincipals) + @($caPolicies.conditions.clientApplications.excludeServicePrincipals) | Sort-Object -Unique | Where-Object { isValidGuid $_ }
        $spnRequests = $spnIds | ForEach-Object {
            @{
                id = $_
                method = "GET"
                url = "servicePrincipals/$($_)?`$select=displayName"
            }
        }
        if ( $spnRequests ) { $spnCollection = Invoke-GtGraphBatchRequest -requests $spnRequests }
    }

    # Build role lookup hashtable (CA policies reference roles by roleTemplateId which equals id in directoryRoleTemplates)
    $roleCollection = @{}
    if ($roleTemplates) {
        $roleTemplates | ForEach-Object { 
            $roleCollection[$_.id] = $_.displayName
        }
    }

    # Helper function to resolve Ids to Names
    function Resolve-IdToName {
        <#
        .SYNOPSIS
        Resolves IDs to display names using a lookup hashtable.

        .DESCRIPTION
        Returns the property value for each ID, or the ID itself when it cannot be resolved.

        .PARAMETER Ids
        IDs to resolve.

        .PARAMETER Collection
        Hashtable of objects keyed by ID.

        .PARAMETER PropertyName
        Property to return from each object. Defaults to displayName. If empty, the hashtable value itself is returned.

        .EXAMPLE
        Resolve-IdToName -Ids $policy.conditions.users.includeGroups -Collection $groupsById
        Returns group display names (or the original IDs if not found).
        #>
        param(
            [AllowEmptyCollection()][string[]]$Ids,
            [hashtable]$Collection,
            [string]$PropertyName = 'displayName'
        )
        if ( -not $Ids -or -not $Collection ) { return $Ids }
        $Ids.ForEach({
            $value = if ($PropertyName) { $Collection[$_].$PropertyName } else { $Collection[$_] }
            if ($value) { $value } else { $_ }
        })
    }

    # Translate GUIDs to friendly names
    foreach ($policy in $caPolicies) {
        # Users
        $policy.conditions.users.includeUsers = Resolve-IdToName -Ids $policy.conditions.users.includeUsers -Collection $userIdCollection -PropertyName 'userPrincipalName'
        $policy.conditions.users.excludeUsers = Resolve-IdToName -Ids $policy.conditions.users.excludeUsers -Collection $userIdCollection -PropertyName 'userPrincipalName'
        
        # Groups
        $policy.conditions.users.includeGroups = Resolve-IdToName -Ids $policy.conditions.users.includeGroups -Collection $groupIdCollection
        $policy.conditions.users.excludeGroups = Resolve-IdToName -Ids $policy.conditions.users.excludeGroups -Collection $groupIdCollection

        # Roles
        $policy.conditions.users.includeRoles = Resolve-IdToName -Ids $policy.conditions.users.includeRoles -Collection $roleCollection -PropertyName $null
        $policy.conditions.users.excludeRoles = Resolve-IdToName -Ids $policy.conditions.users.excludeRoles -Collection $roleCollection -PropertyName $null

        # Locations (may be null)
        if ($policy.conditions.locations) {
            $policy.conditions.locations.includeLocations = Resolve-IdToName -Ids $policy.conditions.locations.includeLocations -Collection $namedLocationCollection
            $policy.conditions.locations.excludeLocations = Resolve-IdToName -Ids $policy.conditions.locations.excludeLocations -Collection $namedLocationCollection
        }

        # Service Principals (may be null)
        if ($policy.conditions.clientApplications) {
            $policy.conditions.clientApplications.includeServicePrincipals = Resolve-IdToName -Ids $policy.conditions.clientApplications.includeServicePrincipals -Collection $spnCollection
            $policy.conditions.clientApplications.excludeServicePrincipals = Resolve-IdToName -Ids $policy.conditions.clientApplications.excludeServicePrincipals -Collection $spnCollection
        }

        # Applications
        $policy.conditions.applications.includeApplications = Resolve-IdToName -Ids $policy.conditions.applications.includeApplications -Collection $tenantAppCollection -PropertyName $null
        $policy.conditions.applications.excludeApplications = Resolve-IdToName -Ids $policy.conditions.applications.excludeApplications -Collection $tenantAppCollection -PropertyName $null
    }

    if ( $outputType -eq "html" ) { $caPolicies | Export-GtHtmlReport -ReportTitle "Conditional Access Policies" -path ".\PSGraphToolbox_ConditionalAccessPolicies_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $caPolicies}
}