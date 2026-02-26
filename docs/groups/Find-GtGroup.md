---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Find-GtGroup.md
schema: 2.0.0
---

# Find-GtGroup

## SYNOPSIS
Search for Entra ID groups by displayName (partial match).

## SYNTAX

```
Find-GtGroup [-SearchString] <String> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
Searches Microsoft Entra ID (Azure AD) groups using a partial match on displayName.
Returns a list of groups with basic properties (id, displayName, description, createdDateTime, groupTypes, mailEnabled, securityEnabled) by default.
Uses Microsoft Graph API (beta version) and supports additional property selection via -AdditionalProperties.
Minimum 3 characters required for search string.
Results are not paged.

Requires scopes: Group.Read.All

## EXAMPLES

### EXAMPLE 1
```
Find-GtGroup "Sales"
```

Returns all groups with 'Sales' in their displayName.

### EXAMPLE 2
```
Find-GtGroup "Admin" -AdditionalProperties "membershipRule"
```

Returns groups with 'Admin' in displayName, including the membershipRule property.

## PARAMETERS

### -SearchString
The search string (min 3 chars).
Performs partial match on group displayName.
Case-insensitive.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalProperties
Comma-separated list of additional properties to include in the response (e.g., "membershipRule,assignedLabels").

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Uses Microsoft Graph API beta version for search capability.
Returned properties can be customized.
Does not support advanced OData filters.

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Find-GtGroup.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Find-GtGroup.md)

