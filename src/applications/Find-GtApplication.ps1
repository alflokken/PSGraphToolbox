function Find-GtApplication {
    <#
    .SYNOPSIS
    Search Entra ID application registrations by displayName, id or appId.

    .DESCRIPTION
    [AI-GENERATED] This function was generated using Claude Opus 4.8.

    Finds application registrations by displayName, or by exact object id / appId (GUID), and returns one object per match with:
    - Basic properties (sign-in audience, publisher, identifier URIs, notes, tags, created date)
    - Owners of the application registration
    - Requested API permissions (requiredResourceAccess), resolved to Resource:Permission (delegated and application)
    - Permissions the app exposes itself (published delegated scopes, app roles, pre-authorized app count)
    - Credentials: secrets, certificates (with expiry, sorted by end date) and federated identity credentials, plus a credentialStatus summary
    - Sign-in configuration (redirect URIs, implicit grant, fallback public client, token encryption, group and optional claims)

    credentialStatus covers secrets and certificates only: none, ok, expiring (within 30 days) or expired (any credential past its end date).
    Federated credentials do not expire and are listed separately. Secret hints and values are never returned.

    This describes the application's design-time configuration. Tenant usage (assignments, consented permissions, owners of the enterprise app)
    belongs to the service principal - see Find-GtServicePrincipal. For tenant-wide credential expiry use Get-GtAppCredentialReport.

    Lookups are scoped to the matched applications only, using batched requests.
    Permission names are resolved only for the resource APIs the matches actually request permissions from;
    permissions of resource APIs that cannot be resolved are shown by ID. Queries the beta endpoint.

    Requires scopes: Application.Read.All.

    .PARAMETER SearchString
    Search string (3-99 chars). A GUID is matched exactly against id or appId; any other string is a displayName
    search that matches words starting with the string (e.g. 'contoso' matches 'Contoso HR App').

    .PARAMETER AdditionalProperties
    Extra application properties to include in results (comma separated, no spaces, e.g. serviceManagementReference,disabledByMicrosoftStatus).

    .OUTPUTS
    One PSObject per application with:
    id, displayName, appId, signInAudience, createdDateTime, publisherDomain, verifiedPublisher (display name), identifierUris, notes, tags,
    any -AdditionalProperties,
    owners (UPN or displayName),
    credentialStatus (none, ok, expiring, expired),
    secrets (displayName, keyId, startDateTime, endDateTime, expired), certificates (same plus type and usage),
    federatedCredentials (name, issuer, subject, audiences),
    apiPermissionsDelegated, apiPermissionsApplication (Resource:Permission),
    publishedDelegatedScopes, publishedAppRoles, preAuthorizedAppCount,
    webRedirectUris, spaRedirectUris, publicClientRedirectUris, implicitIdToken, implicitAccessToken, isFallbackPublicClient,
    tokenEncryption (true if a token encryption key is set), groupMembershipClaims, optionalClaims (true if optional claims are configured).

    .EXAMPLE
    Find-GtApplication "contoso"
    Returns application registrations with a word in displayName starting with 'contoso'.

    .EXAMPLE
    Find-GtApplication "00000000-0000-0000-0000-000000000000"
    Returns the application registration with the given appId (or object id).

    .EXAMPLE
    Find-GtApplication "contoso" | Select-Object displayName, owners, apiPermissionsApplication
    Shows owners and requested application permissions for matching app registrations.

    .EXAMPLE
    Find-GtApplication "contoso" | Select-Object displayName, credentialStatus, secrets
    Shows credential status and secret expiry for matching app registrations.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/applications/Find-GtApplication.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateLength(3, 99)]
        [String]$SearchString,

        [Parameter(Mandatory = $false)]
        [ValidatePattern("^[a-z0-9,]+$")]
        [String]$AdditionalProperties
    )

    $queryParams = @{ resourcePath = "applications"; apiVersion = "beta" }
    $queryParams.select = "id,appId,displayName,signInAudience,createdDateTime,publisherDomain,verifiedPublisher,identifierUris,notes,tags,isFallbackPublicClient,tokenEncryptionKeyId,groupMembershipClaims,optionalClaims,web,spa,publicClient,requiredResourceAccess,api,appRoles,keyCredentials,passwordCredentials"
    if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select),$AdditionalProperties" }
    if ( $SearchString | isValidGuid ) { $queryParams.filter = "id eq '$SearchString' or appId eq '$SearchString'" }
    else { $queryParams.search = "`"displayName:$SearchString`"" }

    Write-GtVerbose "Searching applications with $($queryParams.search) $($queryParams.filter)"
    try { $applications = @(Invoke-GtGraphRequest @queryParams -Verbose:$false) }
    catch { throw $_ }
    if ( -not $applications ) { return }

    # owners and federated credentials (one batch; $expand is not supported alongside $search)
    $appRequests = @()
    $index = 0
    foreach ( $app in $applications ) {
        $appRequests += @{ id = "$index-owners"; method = "GET"; url = "applications/$($app.id)/owners?`$select=id,userPrincipalName,displayName" }
        $appRequests += @{ id = "$index-fics";   method = "GET"; url = "applications/$($app.id)/federatedIdentityCredentials?`$select=name,issuer,subject,audiences" }
        $index++
    }
    Write-GtVerbose "Loading owners and federated credentials for $($applications.Count) application(s)"
    $appResponses = Invoke-GtGraphBatchRequest -Requests $appRequests -Verbose:$false

    # resolve names only for the resource APIs the matches request permissions from (scopes/appRoles only when needed)
    $needScopes = @{}
    $needRoles = @{}
    foreach ( $app in $applications ) {
        foreach ( $rra in $app.requiredResourceAccess ) {
            if ( -not $rra.resourceAppId ) { continue }
            foreach ( $ra in $rra.resourceAccess ) {
                if ( $ra.type -eq "Scope" ) { $needScopes[[string]$rra.resourceAppId] = $true }
                elseif ( $ra.type -eq "Role" ) { $needRoles[[string]$rra.resourceAppId] = $true }
            }
        }
    }
    $resourceAppIds = @($needScopes.Keys) + @($needRoles.Keys) | Select-Object -Unique
    $resourceRequests = @()
    foreach ( $resourceAppId in $resourceAppIds ) {
        $select = "id,displayName"
        if ( $needScopes.ContainsKey($resourceAppId) ) { $select = "$select,oauth2PermissionScopes" }
        if ( $needRoles.ContainsKey($resourceAppId) ) { $select = "$select,appRoles" }
        $resourceRequests += @{ id = $resourceAppId; method = "GET"; url = "servicePrincipals(appId='$resourceAppId')?`$select=$select" }
    }
    $resourceNames = @{}
    $scopeMaps = @{}
    $roleMaps = @{}
    if ( $resourceRequests ) {
        Write-GtVerbose "Resolving permission names from $($resourceRequests.Count) resource application(s)"
        # a deleted resource app returns 404, those fall back to the raw id
        $resourceResponses = Invoke-GtGraphBatchRequest -Requests $resourceRequests -Verbose:$false -WarningAction SilentlyContinue
        foreach ( $resourceAppId in $resourceResponses.Keys ) {
            $resource = $resourceResponses[$resourceAppId]
            $resourceNames[$resourceAppId] = $resource.displayName -replace '\s', ''
            $scopeMap = @{}; foreach ( $s in $resource.oauth2PermissionScopes ) { $scopeMap[[string]$s.id] = $s.value }
            $roleMap  = @{}; foreach ( $r in $resource.appRoles ) { $roleMap[[string]$r.id] = $r.value }
            $scopeMaps[$resourceAppId] = $scopeMap
            $roleMaps[$resourceAppId] = $roleMap
        }
    }

    $extraProperties = @()
    if ( $AdditionalProperties ) { $extraProperties = $AdditionalProperties -split "," | Where-Object { $_ } }

    $now = Get-Date
    $expiringBefore = $now.AddDays(30)

    # secret/certificate entry without secret hint or value
    function toCredentialEntry {
        param($Credential, [switch]$Certificate)
        $end = [datetime]$Credential.endDateTime
        $entry = New-Object -TypeName PSObject
        $entry | Add-Member -NotePropertyName displayName   -NotePropertyValue $Credential.displayName
        $entry | Add-Member -NotePropertyName keyId         -NotePropertyValue $Credential.keyId
        if ( $Certificate ) {
            $entry | Add-Member -NotePropertyName type      -NotePropertyValue $Credential.type
            $entry | Add-Member -NotePropertyName usage     -NotePropertyValue $Credential.usage
        }
        $entry | Add-Member -NotePropertyName startDateTime -NotePropertyValue $Credential.startDateTime
        $entry | Add-Member -NotePropertyName endDateTime   -NotePropertyValue $Credential.endDateTime
        $entry | Add-Member -NotePropertyName expired       -NotePropertyValue ($end -lt $now)
        $entry
    }

    $index = 0
    foreach ( $app in $applications ) {

        $owners = @($appResponses["$index-owners"] | ForEach-Object { if ( $_.userPrincipalName ) { $_.userPrincipalName } else { $_.displayName } })

        $secrets      = @($app.passwordCredentials | Sort-Object { [datetime]$_.endDateTime } | ForEach-Object { toCredentialEntry -Credential $_ })
        $certificates = @($app.keyCredentials      | Sort-Object { [datetime]$_.endDateTime } | ForEach-Object { toCredentialEntry -Credential $_ -Certificate })
        $federatedCredentials = @($appResponses["$index-fics"] | ForEach-Object {
            $fic = New-Object -TypeName PSObject
            $fic | Add-Member -NotePropertyName name      -NotePropertyValue $_.name
            $fic | Add-Member -NotePropertyName issuer    -NotePropertyValue $_.issuer
            $fic | Add-Member -NotePropertyName subject   -NotePropertyValue $_.subject
            $fic | Add-Member -NotePropertyName audiences -NotePropertyValue @($_.audiences)
            $fic
        })

        $credentialStatus = "none"
        $expiryDates = @(@($secrets) + @($certificates) | ForEach-Object { [datetime]$_.endDateTime })
        if ( $expiryDates.Count -gt 0 ) {
            $credentialStatus = "ok"
            if ( $expiryDates | Where-Object { $_ -lt $expiringBefore } ) { $credentialStatus = "expiring" }
            if ( $expiryDates | Where-Object { $_ -lt $now } ) { $credentialStatus = "expired" }
        }

        $delegatedPermissions = @()
        $applicationPermissions = @()
        foreach ( $rra in $app.requiredResourceAccess ) {
            $resourceAppId = [string]$rra.resourceAppId
            $resourceName = $resourceAppId
            if ( $resourceNames.ContainsKey($resourceAppId) ) { $resourceName = $resourceNames[$resourceAppId] }
            foreach ( $ra in $rra.resourceAccess ) {
                $permission = $ra.id
                if ( $ra.type -eq "Scope" ) {
                    if ( $scopeMaps.ContainsKey($resourceAppId) -and $scopeMaps[$resourceAppId][[string]$ra.id] ) { $permission = $scopeMaps[$resourceAppId][[string]$ra.id] }
                    $delegatedPermissions += "${resourceName}:$permission"
                }
                elseif ( $ra.type -eq "Role" ) {
                    if ( $roleMaps.ContainsKey($resourceAppId) -and $roleMaps[$resourceAppId][[string]$ra.id] ) { $permission = $roleMaps[$resourceAppId][[string]$ra.id] }
                    $applicationPermissions += "${resourceName}:$permission"
                }
            }
        }

        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -NotePropertyName id                        -NotePropertyValue $app.id
        $obj | Add-Member -NotePropertyName displayName               -NotePropertyValue $app.displayName
        $obj | Add-Member -NotePropertyName appId                     -NotePropertyValue $app.appId
        $obj | Add-Member -NotePropertyName signInAudience            -NotePropertyValue $app.signInAudience
        $obj | Add-Member -NotePropertyName createdDateTime           -NotePropertyValue $app.createdDateTime
        $obj | Add-Member -NotePropertyName publisherDomain           -NotePropertyValue $app.publisherDomain
        $obj | Add-Member -NotePropertyName verifiedPublisher         -NotePropertyValue $app.verifiedPublisher.displayName
        $obj | Add-Member -NotePropertyName identifierUris            -NotePropertyValue @($app.identifierUris)
        $obj | Add-Member -NotePropertyName notes                     -NotePropertyValue $app.notes
        $obj | Add-Member -NotePropertyName tags                      -NotePropertyValue @($app.tags)
        foreach ( $property in $extraProperties ) { if ( -not $obj.PSObject.Properties[$property] ) { $obj | Add-Member -NotePropertyName $property -NotePropertyValue $app.$property } }
        $obj | Add-Member -NotePropertyName owners                    -NotePropertyValue $owners
        $obj | Add-Member -NotePropertyName credentialStatus          -NotePropertyValue $credentialStatus
        $obj | Add-Member -NotePropertyName secrets                   -NotePropertyValue $secrets
        $obj | Add-Member -NotePropertyName certificates              -NotePropertyValue $certificates
        $obj | Add-Member -NotePropertyName federatedCredentials      -NotePropertyValue $federatedCredentials
        $obj | Add-Member -NotePropertyName apiPermissionsDelegated   -NotePropertyValue @($delegatedPermissions | Select-Object -Unique)
        $obj | Add-Member -NotePropertyName apiPermissionsApplication -NotePropertyValue @($applicationPermissions | Select-Object -Unique)
        $obj | Add-Member -NotePropertyName publishedDelegatedScopes  -NotePropertyValue @($app.api.oauth2PermissionScopes | ForEach-Object { $_.value })
        $obj | Add-Member -NotePropertyName publishedAppRoles         -NotePropertyValue @($app.appRoles | ForEach-Object { $_.value })
        $obj | Add-Member -NotePropertyName preAuthorizedAppCount     -NotePropertyValue @($app.api.preAuthorizedApplications).Count
        $obj | Add-Member -NotePropertyName webRedirectUris           -NotePropertyValue @($app.web.redirectUris)
        $obj | Add-Member -NotePropertyName spaRedirectUris           -NotePropertyValue @($app.spa.redirectUris)
        $obj | Add-Member -NotePropertyName publicClientRedirectUris  -NotePropertyValue @($app.publicClient.redirectUris)
        $obj | Add-Member -NotePropertyName implicitIdToken           -NotePropertyValue $app.web.implicitGrantSettings.enableIdTokenIssuance
        $obj | Add-Member -NotePropertyName implicitAccessToken       -NotePropertyValue $app.web.implicitGrantSettings.enableAccessTokenIssuance
        $obj | Add-Member -NotePropertyName isFallbackPublicClient    -NotePropertyValue $app.isFallbackPublicClient
        $obj | Add-Member -NotePropertyName tokenEncryption           -NotePropertyValue ([bool]$app.tokenEncryptionKeyId)
        $obj | Add-Member -NotePropertyName groupMembershipClaims     -NotePropertyValue $app.groupMembershipClaims
        $obj | Add-Member -NotePropertyName optionalClaims            -NotePropertyValue ([bool]$app.optionalClaims)
        $obj
        $index++
    }
}
