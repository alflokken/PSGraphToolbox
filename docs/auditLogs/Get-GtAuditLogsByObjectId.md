---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtAuditLogsByObjectId.md

TODO: Improve. Output is ok for users and groups, not so much for policy, roles etc
schema: 2.0.0
---

# Get-GtAuditLogsByObjectId

## SYNOPSIS
Get audit logs for a specific object.

## SYNTAX

```
Get-GtAuditLogsByObjectId [-inputObject] <Object> [-startDate <DateTime>] [-raw] [<CommonParameters>]
```

## DESCRIPTION
Retrieves directory audit logs where the specified object is either:
- A target of the action (targetResources)
- The initiator of the action (initiatedBy) (user only)

The output is enriched with resolved friendly names:
- Converts GUID references to displayName (groups, devices, etc.)
- Adds dynamic properties for each target resource type (targetResourceUser, targetResourceGroup, etc.)
- Converts timestamps to local time

Requires scopes: AuditLog.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtAuditLogsByObjectId "user@zavainc.com"
```

Returns audit logs for user from last 30 days.

### EXAMPLE 2
```
$user | auditLog -startDate (Get-Date).AddDays(-7)
```

Returns audit logs from last 7 days for piped user object.

## PARAMETERS

### -inputObject
Object (user, group) or object ID to get audit logs for.
Accepts GUID, UPN, or object with id/userPrincipalName property.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -startDate
Start date for the query.
Defaults to 30 days ago.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-Date).AddDays(-30)
Accept pipeline input: False
Accept wildcard characters: False
```

### -raw
Return raw audit log objects without processing/enrichment.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtAuditLogsByObjectId.md

TODO: Improve. Output is ok for users and groups, not so much for policy, roles etc](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtAuditLogsByObjectId.md

TODO: Improve. Output is ok for users and groups, not so much for policy, roles etc)

