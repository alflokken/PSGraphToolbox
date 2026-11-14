---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Find-GtGroup.md
schema: 2.0.0
---

# Find-GtGroup

## SYNOPSIS
Search for Entra ID groups by displayName.

## SYNTAX

```
Find-GtGroup [-SearchString] <String> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
Searches Microsoft Entra ID (Azure AD) groups by displayName ($search, beta endpoint).
Matches words in displayName that start with the search string (e.g.
'sales' matches 'EMEA Sales Team').
Returns all matching groups (results are paged automatically) with basic properties (id, displayName, description, createdDateTime, groupTypes, mailEnabled, securityEnabled) by default.
Supports additional property selection via -AdditionalProperties.
Minimum 3 characters required for search string.

Requires scopes: Group.Read.All

## EXAMPLES

### EXAMPLE 1
```
Find-GtGroup "Sales"
```

Returns all groups with a word in displayName starting with 'Sales'.

### EXAMPLE 2
```
Find-GtGroup "Admin" -AdditionalProperties "membershipRule"
```

Returns matching groups, including the membershipRule property.

## PARAMETERS

### -SearchString
The search string (3-99 chars).
Word-prefix match on group displayName.
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
Uses the Microsoft Graph beta endpoint.
Does not support OData filters; use Invoke-GtGraphRequest -Filter for that.

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Find-GtGroup.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/groups/Find-GtGroup.md)

