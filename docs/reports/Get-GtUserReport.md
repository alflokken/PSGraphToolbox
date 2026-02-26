---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtUserReport.md
schema: 2.0.0
---

# Get-GtUserReport

## SYNOPSIS
Get a flat report of users or guests with sign-in activity.

## SYNTAX

```
Get-GtUserReport [[-UserType] <String>] [[-MonthsInactive] <Int32>] [[-outputType] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Retrieves users or guests from Entra ID with key governance data:
- Account status (enabled/disabled)
- Sign-in activity (last sign-in, last non-interactive sign-in)
- Sync status (cloud-only vs hybrid)
- inactive account detection based on configurable threshold

Requires scopes: User.Read.All, AuditLog.Read.All (for signInActivity).

## EXAMPLES

### EXAMPLE 1
```
Get-GtUserReport
```

Returns all member users as HTML report.

### EXAMPLE 2
```
Get-GtUserReport -UserType Guest -MonthsInactive 12
```

Returns guest users, flagging those inactive for 12+ months as inactive.

### EXAMPLE 3
```
Get-GtUserReport -UserType All -outputType PSObject
```

Returns all users as PSObject for further processing.

## PARAMETERS

### -UserType
Filter by user type: Member, Guest, or All.
Defaults to Member.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Member
Accept pipeline input: False
Accept wildcard characters: False
```

### -MonthsInactive
Number of months without successful sign-in to flag as inactive.
Defaults to 6.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 6
Accept pipeline input: False
Accept wildcard characters: False
```

### -outputType
Output format: PSObject or html.
Defaults to html.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Html
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Array of user report objects (PSObject mode) or HTML report file path (html mode).
### Each object includes: displayName, userPrincipalName, accountEnabled, userType, state (active/inactive/disabled/never signed in), signInActivity, and manager info.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtUserReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtUserReport.md)

