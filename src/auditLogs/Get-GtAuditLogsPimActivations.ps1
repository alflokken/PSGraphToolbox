function Get-GtAuditLogsPimActivations {
    <#
    .SYNOPSIS
    Retrieves PIM role activation audit logs from Entra ID.

    .DESCRIPTION
    Fetches directory audit logs for successful PIM role activations ('Add member to role completed (PIM activation)')
    in the given time range, sorted newest first. Audit logs are retained for 30 days by default.

    Requires scopes: AuditLog.Read.All.

    .PARAMETER startDate
    The start date for the audit log query. Defaults to 30 days ago.

    .PARAMETER endDate
    The end date for the audit log query. Defaults to current date/time.

    .OUTPUTS
    Array of PIM activation objects with properties: activityDateTime, principalId, userPrincipalName,
    roleId (role definition ID), justification.

    .EXAMPLE
    Get-GtAuditLogsPimActivations
    Returns PIM activation logs for the last 30 days.

    .EXAMPLE
    pimActivations -startDate (Get-Date).AddDays(-7) | Group-Object userPrincipalName
    Groups the last 7 days of activations by user.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtAuditLogsPimActivations.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [datetime]$startDate = (Get-Date).AddDays(-30),
        [Parameter(Mandatory = $false)]
        [datetime]$endDate = (Get-Date)
    )
    
    try {
        [string]$startDateString = Get-Date ($startDate.ToUniversalTime()) -UFormat "%Y-%m-%dT%H:%M:%SZ"
        [string]$endDateString = Get-Date ($endDate.ToUniversalTime()) -UFormat "%Y-%m-%dT%H:%M:%SZ"
        
        $filter = "loggedByService eq 'PIM' and category eq 'RoleManagement' and activityDisplayName eq 'Add member to role completed (PIM activation)' and result eq 'success' and activityDateTime ge $startDateString and activityDateTime le $endDateString"
        
        $auditLogs = Invoke-GtGraphRequest -resourcePath "auditLogs/directoryAudits" -filter $filter -select "activityDateTime,initiatedBy,targetResources,additionalDetails" -orderBy "activityDateTime desc" -top 999

        return $auditLogs | Select-Object @(
            @{ Name = "activityDateTime"; Expression = { $_.activityDateTime } }
            @{ Name = "principalId";      Expression = { $_.initiatedBy.user.id } }
            @{ Name = "userPrincipalName"; Expression = { $_.initiatedBy.user.userPrincipalName } }
            @{ Name = "roleId";           Expression = { ($_.targetResources | Where-Object { $_.type -eq "Role" } | Select-Object -First 1).id } }
            @{ Name = "justification";    Expression = { ($_.additionalDetails | Where-Object { $_.key -eq "justification" }).value } }
        )
    }
    catch { throw $_ }
}