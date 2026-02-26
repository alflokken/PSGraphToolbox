---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtAuditLogsPimActivations.md
schema: 2.0.0
---

# Get-GtAuditLogsPimActivations

## SYNOPSIS
Retrieves PIM role activation audit logs from Entra ID.

## SYNTAX

```
Get-GtAuditLogsPimActivations [[-startDate] <DateTime>] [[-endDate] <DateTime>] [<CommonParameters>]
```

## DESCRIPTION
Fetches audit logs for successful PIM role activations.

Requires scopes: AuditLog.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtAuditLogsPimActivations
```

Returns PIM activation logs for the last 30 days.

## PARAMETERS

### -startDate
The start date for the audit log query.
Defaults to 30 days ago.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-Date).AddDays(-30)
Accept pipeline input: False
Accept wildcard characters: False
```

### -endDate
The end date for the audit log query.
Defaults to current date/time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: (Get-Date)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Array of PIM activation objects with properties: activityDateTime, principalId, userPrincipalName, roleId, justification.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtAuditLogsPimActivations.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtAuditLogsPimActivations.md)

