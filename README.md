<p align="center">
  <img width="300" height="189" src="docs/img/psgt-logo.png">
</p>

<h1 align="center">PowerShell Graph Toolbox</h1>

<p align="center">
  <em>Microsoft Graph and Entra ID tooling for PowerShell.<br> Pipeline-friendly, and works in locked-down environments.</em>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#features">Features</a> •
  <a href="/docs/">Docs</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/PsGraphToolbox"><img src="https://img.shields.io/powershellgallery/v/PsGraphToolbox?label=PSGallery&color=blue" alt="PowerShell Gallery Version"></a>
  <a href="LICENSE.txt"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE" alt="PowerShell 5.1+ | 7+">
  <a href="https://www.powershellgallery.com/packages/PsGraphToolbox"><img src="https://img.shields.io/powershellgallery/dt/PsGraphToolbox" alt="Downloads"></a>
</p>

---

A collection of PowerShell functions for Microsoft Graph and Entra ID, built around `Invoke-GtGraphRequest`, a wrapper for `Invoke-MgGraphRequest` that handles pagination and OData query parameters automatically. On top of that: batching with throttle handling, delta sync, and ready-made functions and HTML reports for users, groups, apps, roles, devices and audit logs.

**Runs where other modules can't.** Works in Windows PowerShell 5.1 under Constrained Language Mode (AppLocker / WDAC-hardened admin hosts) as well as PowerShell 7+. Pure PowerShell, with a single dependency: `Microsoft.Graph.Authentication`.

---

## Quick Start

```powershell
# Install the module
Install-Module -Name PsGraphToolbox -Scope CurrentUser

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"

# Search for users
Find-GtUser "Vincent"

# Generate an HTML report on Entra ID role assignments
Get-GtDirectoryRoleMemberReport
```

---

## Features

### Core

<details>
<summary><b>Invoke-GtGraphRequest</b> - Graph Explorer-style queries from PowerShell</summary>

Core function for Graph API calls. Supports OData parameters, automatic pagination, and automatically sets the ConsistencyLevel header for search queries. All dateTime values in the response are converted from UTC to local time.

```powershell
# Simple query
Invoke-GtGraphRequest -resourcePath "me"

# With OData parameters
Invoke-GtGraphRequest -resourcePath "users" -filter "accountEnabled eq true" -select "displayName" -top 3 -PageLimit 1 

# Search (ConsistencyLevel header added automatically)
Invoke-GtGraphRequest -resourcePath "users" -search '"displayName:john"' -select "id,displayName"

# Beta API
Invoke-GtGraphRequest -resourcePath "users" -select "id,displayName,signInActivity" -apiVersion beta

# Pagination is automatic
$allUsers = Invoke-GtGraphRequest -resourcePath "users" -select "id,displayName"
$allUsers.Count  # Returns all users, not just first page
```

</details>

<details>
<summary><b>Invoke-GtGraphBatchRequest</b> - Batch multiple API calls</summary>

* Automatically splits requests into batches of 20 (Graph API limit)
* Respects Retry-After headers for throttling (by waiting and retrying failed requests)
* Writes progress to the console with request counts and timing
* Returns a hashtable of results keyed by request ID for easy access

```powershell
# Prepare multiple requests:
$requests = foreach ( $id in $users.id ) {
     @{
        id     = $id
        method = "GET"
        url    = "users/$id/authentication/methods"
    }
}

# Execute batch request
$results = Invoke-GtGraphBatchRequest -Requests $requests

# Access results by request ID (hashtable keys match the request 'id' property in each request)
$results["request-id-here"]

# Enumerate all results
$results.GetEnumerator()
```

</details>

<details>
<summary><b>Sync-GtGraphResourceDelta</b> - Synchronize Graph resources using delta queries with persistent state tracking</summary>

For additional details and examples, see the blog post [Microsoft Graph Delta Query in PowerShell](https://alflokken.github.io/posts/graph-delta-queries/).

```powershell
$syncParams = @{
    ResourcePath     = 'users/delta'
    SelectProperties = 'id,userPrincipalName,accountEnabled,displayName'
    StoragePath      = '.\userDeltaState.json'
}

# Initial sync
$result = Sync-GtGraphResourceDelta @syncParams

# Subsequent calls fetch only changes
$result = Sync-GtGraphResourceDelta @syncParams

# Access results
$result.CurrentState.value

# Changelog of changes since last sync
$result.ChangeLog 
```

</details>

### Reports

Bootstrap-styled HTML reports with search, sorting, and pagination. To get objects instead, use `-outputType PSObject` (or `-Raw` for `Get-GtAppPermissionsReport`).

| Report | Screenshot | Command | Description |
|--------|:----------:|---------|-------------|
| **Users** | [📷](docs/img/htmlReport_users.png) | `Get-GtUserReport` | Members or guests with sign-in activity, state, licensing and sponsors. Requires `User.Read.All`, `AuditLog.Read.All` |
| **App Credentials** | [📷](docs/img/htmlReport_appCreds.png) | `Get-GtAppCredentialReport` | Secrets & certificates with expiry. Requires `Application.Read.All` |
| **App Permissions** | [](docs/img/htmlReport_appPerms.png) | `Get-GtAppPermissionsReport` | Service principals with app role assignments, delegated grants and directory roles. Requires `Application.Read.All`, `Directory.Read.All` |
| **Directory Roles** | [📷](docs/img/htmlReport_roles.png) | `Get-GtDirectoryRoleMemberReport` | Role assignments + PIM eligibility, with start/end dates. Requires `RoleManagement.Read.Directory` |
| **Conditional Access** | [📷](docs/img/htmlReport_capol.png) | `Get-GtConditionalAccessPolicyReport` | CA policies with resolved GUIDs. Requires `Policy.Read.All` |
| **SAML Certificates** | [](docs/img/htmlReport_saml.png) | `Get-GtSamlCertificateReport` | SAML signing certificate expiry. Requires `Application.Read.All` |
| **Recommendations** | [](docs/img/htmlReport_recommendations.png) | `Get-GtDirectoryRecommendations` | Entra ID recommendations with impacted resources. Requires `DirectoryRecommendations.Read.All` |
| **Generic** | | `Export-GtHtmlReport` | Any PowerShell objects to HTML |

```powershell
# Generate a report (default output is HTML)
Get-GtConditionalAccessPolicyReport

# Return report data as PowerShell objects
Get-GtUserReport -UserType Guest -MonthsInactive 12 -outputType PSObject | Where-Object state -eq "inactive"

# Pipe any data to HTML
Invoke-GtGraphRequest -resourcePath "users" -select "displayName,mail" -PageLimit 1 | Export-GtHtmlReport
```

### Applications & Service Principals

<details>
<summary><b>Find-GtApplication</b> - Search app registrations</summary>

Search app registrations by displayName, id or appId. Returns owners, requested API permissions, exposed scopes and app roles, secrets, certificates and federated credentials (with status summary) and sign-in configuration.

```powershell
# Search app registrations (displayName, id or appId)
Find-GtApplication "contoso"

# Includes: owners, requested and exposed API permissions, credentials (with status), sign-in configuration
```

</details>

<details>
<summary><b>Find-GtServicePrincipal</b> - Search enterprise apps</summary>

Search enterprise apps (service principals) by displayName, id or appId. Returns owners, assigned users/groups and granted permissions. Optional sign-in activity.

```powershell
# Search enterprise apps (service principals)
Find-GtServicePrincipal "contoso" -IncludeSignInActivity
```

</details>

<details>
<summary><b>Disable-GtApplication</b> - Disable an app registration and service principal</summary>

Disables both the app registration (applies in every tenant) and the service principal in this tenant. Supports `-WhatIf` and `-Confirm`.

```powershell
# Disable the app registration and service principal (prompts for confirmation, supports -WhatIf)
Find-GtServicePrincipal "MigrationWiz" | Disable-GtApplication -WhatIf
```

</details>

<details>
<summary><b>Get-GtAgentIdentities & Get-GtAgentUsers</b> - Agent service accounts</summary>

List agent identities (service principals with owners/sponsors) and agent users (with manager).

```powershell
# Agent identities (with owners and sponsors) and agent users
Get-GtAgentIdentities
Get-GtAgentUsers
```

</details>

### Users & Groups

<details>
<summary><b>Find and retrieve users</b></summary>

```powershell
# Search by display name (partial match)
Find-GtUser "john"
# Returns: id, displayName, userPrincipalName, accountEnabled, mobilePhone, createdDateTime, lastPasswordChangeDateTime

# Get user by UPN or ObjectId
Get-GtUser "john.doe@zavainc.com"

# Pipeline-friendly
Find-GtUser "john doe" | Get-GtUserAuthenticationMethods -MethodType fido2Methods
```

</details>

<details>
<summary><b>Find and manage groups</b></summary>

```powershell
# Search groups
Find-GtGroup "Sales"
# Returns: id, displayName, description, createdDateTime, groupTypes, mailEnabled, securityEnabled

# Get group members
Find-GtGroup "Sales" | Get-GtGroupMembers

# Add member (accepts GUIDs or objects with an id property; UPNs and display names are not accepted)
$user = Get-GtUser "john.doe@zavainc.com"
$group = Find-GtGroup "Sales Team" | Select-Object -First 1
Add-GtMembersToGroup -Group $group -Members $user

# Add multiple members in batches (automatically handles batching for large lists)
Add-GtMembersToGroup -Group $group -Members $addMembers

# Remove member(s) (accepts GUIDs or objects with an id property; prompts for confirmation unless -Confirm:$false)
Remove-GtMembersFromGroup -Group $group -Members $user
```

</details>

### Security & Audit

<details>
<summary><b>Sign-in logs</b></summary>

```powershell
# Get user sign-in logs (defaults to today from 05:00)
Get-GtUserSignIns -InputObject "john.doe@zavainc.com"
# Output columns: dateTime, correlationId, sessionId, userPrincipalName, status, application,
#                 authMethod_0, authMethod_1, tokenType, ipAddress, location, device, client, browser,
#                 compliantDevice, successfulCAPs, failedCAPs, resultType

# Non-interactive sign-ins only
Get-GtUserSignIns -InputObject "john.doe@zavainc.com" -nonInteractive

# Pipeline: find failed sign-ins
Find-GtUser "admin" | Get-GtUserSignIns | Where-Object { $_.status -eq "Failed" }
```

</details>

<details>
<summary><b>Authentication methods & temporary access passes</b></summary>

```powershell
# View registered authentication methods
Get-GtUserAuthenticationMethods -InputObject "john.doe@zavainc.com"
# Returns full authentication method objects from Graph API
# Common properties: @odata.type, id, displayName, createdDateTime (varies by method type)

# View registered FIDO2 security keys
$user | Get-GtUserAuthenticationMethods -MethodType fido2Methods

# Generate a temporary access pass
New-GtUserTemporaryAccessPass $user -LifetimeInMinutes 60 -IsUsableOnce
# Returns: userId, temporaryAccessPass, lifetimeInMinutes, isUsableOnce, startDateTime, methodUsabilityReason
```

</details>

<details>
<summary><b>Session revocation</b></summary>

```powershell
Revoke-GtUserSession -InputObject "john.doe@zavainc.com"
# Returns: userId, success (True/False), timestamp
```

</details>

<details>
<summary><b>Audit logs</b></summary>

```powershell
# Get audit logs for a user (initiated or target, last 30 days)
Get-GtAuditLogsByObjectId "john.doe@zavainc.com"
# Output: activityDateTime, activityDisplayName, result, targetResourceUser, 
#         targetResourceGroup, initiatedBy, category, loggedByService, resultReason

# Get PIM role activations
Get-GtAuditLogsPimActivations -StartDate (Get-Date).AddDays(-30)
# Output: activityDateTime, principalId, userPrincipalName, roleId, justification
```

</details>

<details>
<summary><b>PIM role assignments</b></summary>

```powershell
# Get current user's PIM assignments
Get-GtPimRoleAssignments
# Output: principalId, userPrincipalName, roleDisplayName, roleId, state, scheduleEnd, Status, MemberType

# Filter by state
Get-GtPimRoleAssignments -State Eligible

# Self-activate a role
Invoke-GtPimRoleSelfActivation -Role GlobalReader -DurationInHours 2 -Justification "Audit task"
# Returns: id, completedDateTime, createdDateTime, status, justification
```

</details>

### Devices & Domains

<details>
<summary><b>Device operations</b></summary>

```powershell
# Search devices by display name
Find-GtDevice "macbook"
# Output: id, deviceId, displayName, operatingSystem, operatingSystemVersion, accountEnabled,
#         approximateLastSignInDateTime, createdDateTime, isManaged, isCompliant, profileType,
#         registrationDateTime, trustType, enrollmentType, managementType, deviceModel

# Get device with owner info
Get-GtDevice "12345678-1234-1234-1234-123456789012"
# Includes: registeredOwners, groupMembership

# User's owned devices
Get-GtUserOwnedDevices "john.doe@zavainc.com"
```

</details>

<details>
<summary><b>Domain & tenant info</b></summary>

```powershell
# Get all domains
Get-GtDomains
# Output: id, authenticationType, isVerified (+ federation details if applicable)

# Tenant lookup by domain (no authentication required, uses public metadata)
Get-GtTenantIdFromDomainName -DomainName "zavainc.com"
# Returns: domainName, tenantId

# Reverse tenant lookup (requires authentication, uses Graph API)
Get-GtTenantInformationByTenantId "6babcaad-604b-40ac-a9d7-9fd97c0b779f"

# Current tenant info
Get-GtTenantInfo
# Returns: tenantId, displayName, tenantType, countryCode, createdDateTime,
#          defaultDomain, initialDomain, verifiedDomainCount, domains
```

</details>

### Helpers

Exported helpers, handy in your own scripts. The Graph request, batch and delta functions are covered under [Core](#core).

| Function | Description |
|----------|-------------|
| `ConvertTo-HashTable` | Array to hashtable keyed by a property (much faster than `Group-Object -AsHashTable`) |
| `ConvertTo-GtLocalDateTime` | Recursively converts dateTime values from UTC to local time (objects, hashtables, arrays) |
| `Get-GtGraphDirectoryObjectsByIds` | Bulk lookup of directory objects by id (users, groups, devices, service principals and more) |
| `Split-ArrayIntoChunks` | Split an array into chunks (alias `chunk`) |
| `Write-GtVerbose` | `Write-Verbose` with timestamp |

---

## Contributing

This is a personal toolkit shared publicly. Contributions are welcome, with realistic expectations:

- **Bugs** - Addressed based on severity and personal availability
- **Feature requests** - May not align with my needs. Fork and customize as needed.
- **Pull requests** - Follow patterns in [.github/copilot-instructions.md](.github/copilot-instructions.md)

---

<sub>**AI Disclaimer**<br> Help files are auto-generated. Some code may be AI-assisted. `Export-GtHtmlReport` is fully AI-generated as noted in its help file. The logo is also AI-generated (obviously).</sub>
