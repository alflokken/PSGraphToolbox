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
Retrieves all Conditional Access policies and resolves GUIDs to human-readable names:
- Users, groups, roles referenced in policy conditions
- Applications and service principals
- Named locations

Uses batch queries for efficient resolution of private/tenant-specific apps.

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
Only return policies with state "Enabled".

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

### None.
## OUTPUTS

### Array of policy objects (PSObject mode) or HTML report file path (html mode).
### Each policy includes resolved displayNames for users, groups, roles, applications, and named locations.
### System.Object[] (PSObject) or System.String (html report).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtConditionalAccessPolicyReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtConditionalAccessPolicyReport.md)

