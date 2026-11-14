function Get-GtAuditLogsByObjectId {
    <#
    .SYNOPSIS
    Get audit logs for a specific object.

    .DESCRIPTION
    Retrieves directory audit logs where the specified object is either:
    - A target of the action (targetResources)
    - The initiator of the action (initiatedBy) (user only)
    A UPN is resolved to the object ID first. Results for all piped objects are combined
    and sorted by activityDateTime (newest first).

    The output is enriched with resolved friendly names:
    - initiatedBy is replaced by the initiating user's UPN, or the initiating app's displayName
    - A targetResource<Type> property is added for each target resource type (targetResourceUser, targetResourceGroup, etc.)
    with the target's UPN or displayName; multiple targets are separated by '; '
    - Group and device targets without a displayName are resolved by ID; other types keep the ID
    - Timestamps are in local time

    Requires scopes: AuditLog.Read.All.
    UPN input also needs User.Read.All; resolving group/device names needs Directory.Read.All.

    .PARAMETER inputObject
    Object (user, group) or object ID to get audit logs for.
    Accepts GUID, UPN, or object with id/userPrincipalName property. Accepts pipeline input.

    .PARAMETER startDate
    Start date for the query. Defaults to 30 days ago.

    .PARAMETER raw
    Return raw audit log objects (selected properties only) without enrichment or sorting.

    .OUTPUTS
    Array of audit log objects with activityDateTime, activityDisplayName, result, targetResourceUser, targetResourceGroup,
    initiatedBy, category, loggedByService, resultReason and any other targetResource<Type> properties.

    .EXAMPLE
    Get-GtAuditLogsByObjectId "user@zavainc.com"
    Returns audit logs for user from last 30 days.

    .EXAMPLE
    $user | auditLog -startDate (Get-Date).AddDays(-7)
    Returns audit logs from last 7 days for piped user object.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtAuditLogsByObjectId.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$inputObject,
        [Parameter(Mandatory = $false)]
        [datetime]$startDate = (Get-Date).AddDays(-30),
        [switch]$raw
    )
    # TODO: Improve. Output is ok for users and groups, not so much for policy, roles etc
    begin { $auditLogs = @() }
    process {
        $idFromInputObject = Get-IdFromInputObject -inputObject $inputObject
        if ( $idFromInputObject.type -eq "upn" ) { $id = Invoke-GtGraphRequest -resourcePath "users/$($idFromInputObject.id)" -select "id" | Select-Object -ExpandProperty id }
        else { $id = $idFromInputObject.id }
        $dateTime = Get-Date ($startDate.ToUniversalTime()) -UFormat "%Y-%m-%dT%H:%M:%SZ" 
        $auditLogs += Invoke-GtGraphRequest -apiVersion v1.0 -resourcePath "auditLogs/directoryAudits" `
            -filter "(targetResources/any(t: t/id eq '$id') or initiatedBy/user/id eq '$id') and activityDateTime ge $dateTime" `
            -select "activityDateTime,category,loggedByService,activityDisplayName,initiatedBy,targetResources,result,resultReason" -top 999
    }
    end {
        if ( $raw ) { return $auditLogs }

        # placeholder for resourceTargetResources to resolve (keyed by type)
        $resolveHashtable = @{}

        # add dynamic properties for each target resource type and prepare resolveHashtable by type (id and friendlyName)
        $auditLogs.targetResources.type | Sort-Object -Unique | %{ "targetResource$_" } | %{ 
            $auditLogs | Add-Member -MemberType NoteProperty -Name $_ -Value $null
            $resolveHashtable[$_] = @{}
        }
        $auditLogs | Add-member -MemberType NoteProperty -Name "targetResourceUnknown" -Value @()

        foreach ( $entry in $auditLogs ) {
            $entry.initiatedBy = if ( $entry.initiatedBy.user.userPrincipalName ) { $entry.initiatedBy.user.userPrincipalName } else { $entry.initiatedBy.app.displayName }
            
            # resolve target resources
            foreach ( $target in ($entry.targetResources | Where-Object { $_.id -notmatch "^/$|^00000000-0000-0000-0000-00000000000" -and $_.type } | Sort-Object id -Unique) ) {
                
                $propertyName = "targetResource$($target.type)"

                if ( $target.userPrincipalName ) { $friendlyName  = $target.userPrincipalName }
                elseif ( $target.displayName ) { $friendlyName = $target.displayName }
                else { 
                    $friendlyName = $target.id
                    $entry.targetResourceUnknown += $propertyName
                    $resolveHashtable[$propertyName][$target.id] = "unknown"
                }

                # set or append
                if ( $entry.$propertyName ) {
                    $entry.$propertyName += "; $friendlyName"
                    # remove from lookup (todo:handle multiple unknowns)
                    if ( $entry.targetResourceUnknown -contains $propertyName ) { $entry.targetResourceUnknown = $entry.targetResourceUnknown | Where-Object { $_ -ne $propertyName } }
                }
                else { $entry.$propertyName = $friendlyName } # set
            }
        }

        # resolve unknown target resources 
        if ( $auditLogs.targetResourceUnknown -contains "targetResourceGroup" ) {
            $groupIds = $auditLogs | Where-Object { $_.targetResourceUnknown -contains "targetResourceGroup" } | Select-Object -ExpandProperty targetResourceGroup | Sort-Object -Unique 
            Write-GtVerbose "Resolving $($groupIds.Count) group IDs..."
            $groupIdCollection = Get-GtGraphDirectoryObjectsByIds -ids $groupIds -type group | ConvertTo-HashTable -keyProperty id
        }
        # cross-reference 
        foreach ( $entry in ($auditLogs | Where-Object { $_.targetResourceUnknown -contains "targetResourceGroup" }) ) {
            if ( $entry.targetResourceGroup -and $groupIdCollection[$entry.targetResourceGroup] ) {
                $entry.targetResourceGroup = $groupIdCollection[$entry.targetResourceGroup].displayName
            }
        }

        # devices
        if ( $auditLogs.targetResourceUnknown -contains "targetResourceDevice" ) {
            $deviceIds = $auditLogs | Where-Object { $_.targetResourceUnknown -contains "targetResourceDevice" } | Select-Object -ExpandProperty targetResourceDevice | Sort-Object -Unique 
            Write-GtVerbose "Resolving $($deviceIds.Count) device IDs..."
            $deviceIdCollection = Get-GtGraphDirectoryObjectsByIds -ids $deviceIds -type device | ConvertTo-HashTable -keyProperty id
        }
        # cross-reference
        foreach ( $entry in ($auditLogs | Where-Object { $_.targetResourceUnknown -contains "targetResourceDevice" }) ) {
            if ( $entry.targetResourceDevice -and $deviceIdCollection[$entry.targetResourceDevice] ) {
                $entry.targetResourceDevice = $deviceIdCollection[$entry.targetResourceDevice].displayName
            }
        }

        return ($auditLogs | Select-Object activityDateTime, activityDisplayName, result, targetResourceUser, targetResourceGroup, initiatedBy, category, loggedByService, resultReason, * -ExcludeProperty targetResourceUnknown, targetResources -ErrorAction SilentlyContinue | Sort-Object activityDateTime -Descending)
    }
}