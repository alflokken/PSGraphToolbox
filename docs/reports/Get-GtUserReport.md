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
Get-GtUserReport [[-UserType] <String>] [[-MonthsInactive] <Int32>] [-IncludeDisabledAccounts]
 [[-outputType] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves users or guests from Entra ID (beta endpoint, required for signInActivity) with key governance data:
- Account status (only enabled accounts, unless -IncludeDisabledAccounts is used)
- Sign-in activity (last successful, last interactive and last non-interactive sign-in, days since last successful sign-in)
- Entra ID P1/P2 license (IsAadLicensed)
- Members: sync status (cloud-only vs hybrid), manager and organization details
- Guests: invitation state, guest domain and sponsors
- State, based on the last successful sign-in:
  active, inactive (no successful sign-in within -MonthsInactive months), never signed in,
  recentlyInvited (guest with a pending invitation changed within -MonthsInactive months), disabled

Requires scopes: User.Read.All, AuditLog.Read.All (for signInActivity).

## EXAMPLES

### EXAMPLE 1
```
Get-GtUserReport
```

Returns all enabled member users as HTML report.

### EXAMPLE 2
```
Get-GtUserReport -UserType Guest -MonthsInactive 12
```

Returns enabled guest users, flagging those without a successful sign-in for 12+ months as inactive.

### EXAMPLE 3
```
Get-GtUserReport -IncludeDisabledAccounts -outputType PSObject
```

Returns all member users, including disabled accounts, as PSObject for further processing.

## PARAMETERS

### -UserType
Filter by user type: Member or Guest.
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
Defaults to 3.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeDisabledAccounts
Include disabled accounts (state 'disabled').
By default only enabled accounts are returned.

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

### PSObject mode: array of flat user objects with id, displayName, userPrincipalName, accountEnabled, userType, state, IsAadLicensed,
### daysSinceSignIn, lastSuccessfulSignIn, lastInteractiveSignIn, lastNonInteractiveSignIn, createdDateTime, plus
### - Member: onPremisesSyncEnabled, manager (UPN), department, jobTitle, companyName, country
### - Guest: externalUserState, externalUserStateChangeDateTime, guestDomain, sponsors (UPN or displayName)
### html mode: nothing is returned. The report (without id) is written to .\PSGraphToolbox_UserReport_<yyyyMMdd_HHmmss>.html
### in the current directory and opened in the default browser.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtUserReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtUserReport.md)

