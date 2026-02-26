<p align="center">
  <img width="300" height="189" src="/docs/img/aiSlop_psgtLogo.png">
</p>

<h1 align="center">PowerShell Graph Toolbox</h1>

<p align="center">
  <em>Lightweight Microsoft Graph utilities for restricted environments</em>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#features">Features</a> •
  <a href="/docs/">Docs</a> •
  <a href="#contributing">Contributing</a>
</p>

---

Collection of PowerShell functions built around `Invoke-GtGraphRequest`, a wrapper for `Invoke-MgGraphRequest` that handles pagination and OData query parameters automatically.

**Why this exists:** I often work in restricted environments with Constrained Language Mode and PowerShell 5.1, where minimal dependencies are required. The only dependency is `Microsoft.Graph.Authentication`. These tools simplify delta queries, batching, and common Graph and Entra ID operations.

---

## Quick Start

```powershell

# Install the module
Install-Module -Name PsGraphToolbox -Scope CurrentUser

# Search for users
Find-GtUser "Vincent"

# Generate a html report on Entra ID role assignments
Get-GtDirectoryRoleMemberReport
```

---

## Features

### Core

<details>
<summary><b>Invoke-GtGraphRequest</b> - Graph Explorer-style queries from PowerShell</summary>

Core function for Graph API calls. Supports OData parameters, automatic pagination, and automatically sets the ConsistencyLevel header for search queries.

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

For additional details and examples, check out my blog post [Microsoft Graph Delta Query in PowerShell](https://alflokken.github.io/posts/graph-delta-queries/).

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

Bootstrap-styled HTML reports with search, sorting, and pagination.

| Report | Screenshot | Command | Description |
|--------|---------|-------------|:----------:|
| **App Credentials** | [📷](docs/img/htmlReport_appCreds.png) | Secrets & certificates with expiry | `Get-GtApplicationCredentialReport` |
| **Directory Roles** | [📷](docs/img/htmlReport_roles.png) | Role assignments + PIM eligibility | `Get-GtDirectoryRoleMemberReport` | 
| **Conditional Access** | [📷](docs/img/htmlReport_capol.png) | CA policies with resolved GUIDs | `Get-GtConditionalAccessPolicyReport` |
| **SAML Certificates** | | SAML signing certificate expiry | `Get-GtSamlCertificateReport` |
| **Generic** | | Any PowerShell objects to HTML | `Export-GtHtmlReport` |

```powershell
# Generate a report
Get-GtConditionalAccessPolicyReport -outputType html

# Pipe any data to HTML
Invoke-GtGraphRequest -resourcePath "users" -select "displayName,mail" -PageLimit 1  | Export-GtHtmlReport
```

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

# Add member (accepts UPNs, GUIDs, or objects)
Add-GtMembersToGroup -Group "Sales Team" -Members "john.doe@zavainc.com"

# Add multiple members in batches (automatically handles batching for large lists)
Add-GtMembersToGroup -Group "Sales Team" -Members $addMembers

# Remove member(s)
Remove-GtMembersFromGroup -Group "Sales Team" -Members $addMembers[0]
```

</details>

### Security & Audit

<details>
<summary><b>Sign-in logs</b></summary>

```powershell
# Get user sign-in logs (defaults to today from 05:00)
Get-GtUserSignIns -InputObject "john.doe@zavainc.com"
# Output columns: dateTime, correlationId, userPrincipalName, status, application, 
#                 authMethod_0, authMethod_1, ipAddress, device, client, browser,
#                 compliantDevice, successfulCAPs, failedCAPs, resultType

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

---

## Contributing

This is a personal toolkit shared publicly. Contributions are welcome, with realistic expectations:

- **Bugs** - Addressed based on severity and personal availability
- **Feature requests** - May not align with my needs. Fork and customize as needed.
- **Pull requests** - Follow patterns in [.github/copilot-instructions.md](.github/copilot-instructions.md)

See [IDEAS.md](IDEAS.md) for potential future features.

---

<sub>**AI Disclaimer**<br> Help files are auto-generated. Some code may be AI-assisted. `Export-GtHtmlReport` is fully AI-generated as noted in its help file. The logo is also AI-generated (obviously).</sub>
