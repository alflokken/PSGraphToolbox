---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtConditionalAccessPolicyReport.md
schema: 2.0.0
---

# Get-GtConditionalAccessPolicyReport

## SYNOPSIS
Get Conditional Access Policies with resolved friendly names.

## SYNTAX

```
Get-GtConditionalAccessPolicyReport [[-outputType] <Object>] [-onlyEnabledPolicies] [<CommonParameters>]
```

## DESCRIPTION
Retrieves all Conditional Access policies (beta endpoint) and resolves GUIDs in the policy conditions to human-readable names:
- Users (as userPrincipalName), groups and directory roles
- Applications and client service principals
- Named locations (including "Multifactor authentication trusted IPs")
IDs that cannot be resolved are kept as-is.

Well-known Microsoft application names are resolved from a public list downloaded from GitHub
(merill/microsoft-info, MicrosoftApps.json, 3-second timeout), so internet access is needed; if the download fails,
errors are written and those applications may be shown by appId.
Other (tenant-specific) applications are resolved
with batch queries.

Requires scopes: Policy.Read.All, Directory.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtConditionalAccessPolicyReport
```

Generates HTML report of all CA policies.

### EXAMPLE 2
```
Get-GtConditionalAccessPolicyReport -onlyEnabledPolicies -outputType PSObject
```

Returns only enabled policies as PowerShell objects.

## PARAMETERS

### -outputType
Output format: PSObject or html.
Defaults to html.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Html
Accept pipeline input: False
Accept wildcard characters: False
```

### -onlyEnabledPolicies
Only return policies with state "enabled" (report-only and disabled policies are excluded).

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

### PSObject mode: array of policy objects as returned by Graph, with the resolved names in place of GUIDs in conditions.
### html mode: nothing is returned. The report is written to .\PSGraphToolbox_ConditionalAccessPolicies_<yyyyMMdd_HHmmss>.html
### in the current directory and opened in the default browser.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtConditionalAccessPolicyReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtConditionalAccessPolicyReport.md)

