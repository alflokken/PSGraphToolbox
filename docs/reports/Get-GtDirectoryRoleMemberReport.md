---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRoleMemberReport.md
schema: 2.0.0
---

# Get-GtDirectoryRoleMemberReport

## SYNOPSIS
Get all Entra ID directory role assignments and eligibilities with resolved names.

## SYNTAX

```
Get-GtDirectoryRoleMemberReport [[-IncludePimActivations] <Boolean>] [[-outputType] <Object>]
 [<CommonParameters>]
```

## DESCRIPTION
Retrieves both active role assignments and PIM eligible roles from Entra ID.
Resolves principal displayNames (users, groups, service principals) and role names.
Optionally includes PIM activation data from audit logs.

PIM activation data is retrieved from the directory audit logs (category: RoleManagement,
activityDisplayName: Add member to role completed (PIM activation)).
Microsoft retains
these logs for 30 days by default, so activation history is limited to that window.

Requires scopes: RoleManagement.Read.Directory, Directory.Read.All.
For PIM activations: AuditLog.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtDirectoryRoleMemberReport
```

Returns all role members with enriched data as HTML report.

### EXAMPLE 2
```
Get-GtDirectoryRoleMemberReport -IncludePimActivations:$false -outputType PSObject
```

Returns role assignments as PSObject array without PIM activation data.

## PARAMETERS

### -IncludePimActivations
Include PIM activation statistics (last 30 days).
Defaults to $true.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -outputType
Output format: PSObject or html.
Defaults to html.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Html
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Array of PSObjects (PSObject mode) or HTML report file path (html mode).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRoleMemberReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtDirectoryRoleMemberReport.md)

