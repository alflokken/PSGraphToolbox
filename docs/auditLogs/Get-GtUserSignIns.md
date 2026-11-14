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
Get-GtUserSignIns [-inputObject] <Object> [-startDate <DateTime>] [-endDate <DateTime>] [-nonInteractive]
 [-raw] [<CommonParameters>]
```

## DESCRIPTION
Retrieves sign-in logs from Entra ID for a specific user (beta endpoint, required for authenticationDetails).
A UPN is resolved to the object ID first.
By default the endpoint returns interactive sign-ins;
use -nonInteractive for non-interactive sign-ins.
Results are sorted newest first.

Requires scopes: AuditLog.Read.All (and User.Read.All to resolve a UPN).

## EXAMPLES

### EXAMPLE 1
```
Get-GtUserSignIns "user@zavainc.com"
```

Returns the user's interactive sign-ins since 05:00 today.

### EXAMPLE 2
```
"user@zavainc.com" | signInLogs -startDate (Get-Date).AddDays(-7) -nonInteractive
```

Returns the user's non-interactive sign-ins from the last 7 days.

## PARAMETERS

### -inputObject
User object (id/userPrincipalName), UPN, or object ID.
Accepts pipeline input.

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
Defaults to 05:00 today (local time).

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-Date).AddDays(-1)
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

### -nonInteractive
Only return non-interactive user sign-ins.

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

### Array of sign-in log objects (raw or transformed). When not raw, each object contains:
### - dateTime: createdDateTime (local time)
### - correlationId, sessionId: last segment only
### - userPrincipalName, application
### - status: "Success" (error code 0), "Interrupted" (50076, 50079, 50097, 50125, 50129, 50140, 50158, 50201, 50207) or "Failed"
### - authMethod_0, authMethod_1: first and second authentication step (method and detail), prefixed "FAILED: " when the step failed
### - tokenType: incoming token type (primaryRefreshToken shown as PRT)
### - ipAddress, location ("country, city")
### - device: device displayName and last segment of the deviceId
### - client: client app used ("Native App" for mobile apps and desktop clients)
### - browser: browser and operating system
### - compliantDevice
### - successfulCAPs, failedCAPs: applied Conditional Access policy names, ';'-separated (names starting with CA<number> are shortened to CA<number>)
### - resultType: sign-in error code
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtUserSignIns.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtUserSignIns.md)

