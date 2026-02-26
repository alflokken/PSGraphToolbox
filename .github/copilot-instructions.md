# PSGraphToolbox Graph Toolkit - AI Coding Instructions

## Project Overview
PowerShell toolkit for Microsoft Entra ID operations via Microsoft Graph API. Uses `Microsoft.Graph` SDK with custom wrappers for pagination, batching, and throttle handling.

**Core Philosophy**: Minimal dependencies, CLM-compatible, PowerShell 5.1+, pipeline-friendly.

---

## ⚠️ CRITICAL: PowerShell 5.1 Constrained Language Mode

**ALL code MUST work in PowerShell 5.1 Constrained Language Mode (CLM).**

### ❌ Prohibited
- Static .NET methods: `[System.IO.File]::ReadAllText()`, `[Guid]::Parse()`
- No [PSCustomObject]@{}: Type accelerator blocked, use New-Object PSObject + Add-Member
- `Add-Type`: Cannot load custom C#
- `[scriptblock]::Create()`: Dynamic script blocks blocked
- COM objects: `New-Object -ComObject`
- Most `New-Object` calls for non-approved types

### ✅ Safe Alternatives
```powershell
# String operations - use operators
$text -replace "a", "b"          # Not: $text.Replace("a", "b")
$text -split ","                 # Not: $text.Split(",")

# GUID operations
[System.Guid]$guid = $string     # Not: [Guid]::Parse($string)

# Date operations  
Get-Date $string                 # Not: [DateTime]::Parse($string)
(Get-Date).ToUniversalTime()     # Not: [DateTime]::UtcNow

# File operations
Get-Content -Path $path -Raw     # Not: [System.IO.File]::ReadAllText()
Set-Content -Path $path -Value $content
Test-Path -Path $path

# HTML encoding
$text -replace "&","&amp;" -replace "<","&lt;" -replace ">","&gt;"
```

---

## ⚠️ AI-Generated Code Marking

**Mark ALL AI-generated code clearly.**

```powershell
# Entire function
<#
.DESCRIPTION
[AI-GENERATED] This function was generated using Claude Sonnet 4.5.
Requires scopes: User.Read.All
#>

# Code block
# [AI-GENERATED START] - Batch processing logic
$chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 20
# [AI-GENERATED END]

# Inline
$sorted = $data | Sort-Object Date  # [AI-GENERATED] sorting logic
```

---

## Architecture Quick Reference

### Core Layer (`core/`)
- **`Invoke-GtGraphRequest`** - Graph API wrapper with auto-pagination, OData support
- **`Invoke-GtGraphBatchRequest`** - Batch processor (20/batch), auto-retry on throttle
- **`Sync-GtGraphResourceDelta`** - Delta sync with state persistence
- **`Get-GtGraphDirectoryObjectsByIds`** - Bulk ID resolver (chunks to 1000)

### Helpers (`helpers/`)
Internal utilities (not exported):
- **`Get-IdFromInputObject`** - Normalizes UPN/GUID/object to ID
- **`isValidGuid`** / **`isValidUserPrincipalName`** - Validation filters
- **`New-GtRequestUri`** - OData URI builder

### Utilities (`utilities/`)
- **`Split-ArrayIntoChunks`** - Array chunking (alias: `chunk`)
- **`Export-GtHtmlReport`** - Bootstrap HTML report generator

---

## Naming Conventions

- **Prefix**: `Gt` for all public functions (e.g., `Get-GtUser`, `Find-GtGroup`)
- **Verbs**: `Get-` (retrieval), `Find-` (search), `Add-`/`Remove-` (mutations), `Invoke-` (actions)
- **Parameters**: PascalCase, full names (no abbreviations)

---

## Key Patterns

### 1. Input Flexibility
Accept UPN, GUID, or objects with `id`/`userPrincipalName`:

```powershell
function Get-GtUser {
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [object]$InputObject
    )
    process {
        $userId = Get-IdFromInputObject -InputObject $InputObject
        Invoke-GtGraphRequest -resourcePath "users/$userId"
    }
}

# All valid:
Get-GtUser "user@contoso.com"
Get-GtUser "guid-here"
$user | Get-GtUser
```

### 2. Always Use Invoke-GtGraphRequest
```powershell
# ✅ Correct - auto-pagination, OData params
$users = Invoke-GtGraphRequest -resourcePath "users" `
    -select "id,displayName" `
    -filter "accountEnabled eq true"

# ❌ Wrong - manual pagination required
$users = Invoke-MgGraphRequest -Uri "..."
```

### 3. OData Parameters with Splatting
```powershell
$params = @{
    resourcePath = "users"
    apiVersion   = "beta"  # or "v1.0" (default)
    select       = "id,displayName,signInActivity"
    filter       = "userType eq 'Member'"
    expand       = "manager(`$select=displayName)"
}
$users = Invoke-GtGraphRequest @params
```

### 4. Batch Processing
```powershell
$chunks = Split-ArrayIntoChunks -Enumerable $userIds -ChunkSize 20
foreach ($chunk in $chunks) {
    $requests = $chunk | ForEach-Object {
        @{ id = $_; method = "GET"; url = "users/$_" }
    }
    $results = Invoke-GtGraphBatchRequest -Requests $requests
}
```

---

## Comment-Based Help Guidelines

**Scale help to function complexity.** Simple functions need minimal help; complex functions need detailed examples.

### Critical Formatting Rule
**Comment-based help keywords (e.g., .EXAMPLE) and their content must be at the SAME indentation level - no tabs/spaces before the description text.**

```powershell
<#
.SYNOPSIS
Retrieves a user from Microsoft Entra ID

.DESCRIPTION
Accepts flexible input (UPN, GUID, or object) and returns user details.
Requires scopes: User.Read.All

.PARAMETER InputObject
User identifier (UPN, GUID, or object with id/userPrincipalName)

.EXAMPLE
Get-GtUser "user@contoso.com"
Retrieves user by UPN

.EXAMPLE
$user | Get-GtUser -Select "id,displayName"
Pipeline usage with custom select
#>
```

### What to Include

**Simple functions (5-20 lines):**
- `.SYNOPSIS` - one sentence
- `.DESCRIPTION` - required scopes, brief explanation
- `.PARAMETER` - for each param
- `.EXAMPLE` - 1-2 examples

**Complex functions (20+ lines, multiple params):**
- Same as above, plus:
- More `.EXAMPLE` entries showing different use cases
- `.NOTES` if special considerations exist
- `.INPUTS` / `.OUTPUTS` only if it aids understanding

**Always include:**
- `.LINK` - Link to the generated documentation on GitHub:
  ```
  .LINK
  https://github.com/alflokken/PSGraphToolbox/blob/main/docs/{category}/{FunctionName}.md
  ```
  Where `{category}` is the folder name under `src/` (e.g., `auditLogs`, `core`, `helpers`)

**Don't include:**
- `PS>` prompt in examples - causes rendering issues
- Raw output after commands - use description instead
- `.INPUTS` / `.OUTPUTS` if obvious from context

### Good Example (Simple Function)
```powershell
<#
.SYNOPSIS
Finds users by display name

.DESCRIPTION
Searches for users with partial display name match.
Requires scopes: User.Read.All

.PARAMETER SearchString
Partial or full display name to search

.EXAMPLE
Find-GtUser "john"
Returns all users with "john" in display name
#>
```

### Good Example (Complex Function)
```powershell
<#
.SYNOPSIS
Retrieves sign-in logs for a user

.DESCRIPTION
Retrieves audit log sign-in events for a specific user within a date range.
Requires scopes: AuditLog.Read.All, Directory.Read.All

.PARAMETER InputObject
User identifier (UPN, GUID, or object)

.PARAMETER StartDate
Start date for log retrieval (defaults to 7 days ago)

.PARAMETER EndDate
End date for log retrieval (defaults to now)

.EXAMPLE
Get-GtUserSignInLogs -InputObject "user@contoso.com"
Retrieves last 7 days of sign-in logs

.EXAMPLE
Get-GtUserSignInLogs -InputObject "user@contoso.com" -StartDate (Get-Date).AddDays(-30)
Retrieves last 30 days of logs

.EXAMPLE
Find-GtUser "john" | Get-GtUserSignInLogs | Where-Object { $_.status.errorCode -ne 0 }
Pipeline usage to find failed sign-ins

.NOTES
Sign-in logs are retained for 30 days in Azure AD
#>
```

---

## Required Permissions

Document in `.DESCRIPTION`:

```powershell
.DESCRIPTION
Retrieves conditional access policies.
Requires scopes: Policy.Read.All
```

---

## Common Code Patterns

### Resolve GUIDs to Names
```powershell
$guidList = $policy.conditions.users.includeUsers
$names = Get-GtGraphDirectoryObjectsByIds -Ids $guidList | Select-Object -ExpandProperty displayName
```

### Date Filtering
```powershell
$date = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ")
$filter = "createdDateTime ge $date"
```

### Progress Reporting
```powershell
$total = $items.Count
$current = 0
foreach ($item in $items) {
    $current++
    Write-Progress -Activity "Processing" -Status "$current of $total" `
        -PercentComplete (($current / $total) * 100)
}
Write-Progress -Activity "Processing" -Completed
```

---

## Performance Tips

1. **Use `$select`** - Only request needed properties
2. **Use batch API** - For multiple individual requests
3. **Use delta queries** - For incremental sync
4. **Server-side filter** - Use `$filter` not `Where-Object`

```powershell
# ❌ Slow
$all = Invoke-GtGraphRequest -resourcePath "users"
$active = $all | Where-Object accountEnabled

# ✅ Fast
$active = Invoke-GtGraphRequest -resourcePath "users" -filter "accountEnabled eq true"
```
