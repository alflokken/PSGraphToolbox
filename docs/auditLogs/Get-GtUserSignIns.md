---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtUserSignIns.md
schema: 2.0.0
---

# Get-GtUserSignIns

## SYNOPSIS
Get sign-in logs for a user.

## SYNTAX

```
Get-GtUserSignIns [-inputObject] <Object> [-startDate <DateTime>] [-endDate <DateTime>] [-raw]
 [<CommonParameters>]
```

## DESCRIPTION
Retrieves sign-in logs from Entra ID for a specific user.
Includes authentication details, location, and status.

Requires scopes: AuditLog.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtUserSignIns "user@zavainc.com"
```

### EXAMPLE 2
```
"user@zavainc.com" | signInLogs -startDate (Get-Date).AddDays(-7)
```

## PARAMETERS

### -inputObject
User object, UPN, or object ID.

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
Defaults to today 05:00.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-Date 05:00)
Accept pipeline input: False
Accept wildcard characters: False
```

### -endDate
End date for the query.
Defaults to now.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-Date)
Accept pipeline input: False
Accept wildcard characters: False
```

### -raw
Return raw sign-in log objects without transformation/flattening.

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

### Array of sign-in log objects (raw or transformed). When not raw, output includes:
### - dateTime: Converted to local time
### - status: Mapped to "Success", "Interrupted", or "Failed"
### - authMethod_0, authMethod_1: Flattened authentication method details
### - device: Includes display name and device ID
### - correlationId: Short form (last segment only)
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtUserSignIns.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtUserSignIns.md)

