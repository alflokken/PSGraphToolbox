---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Find-GtUser.md
schema: 2.0.0
---

# Find-GtUser

## SYNOPSIS
Search Entra ID users by displayName or UPN.

## SYNTAX

```
Find-GtUser [-SearchString] <String> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
Finds users by displayName or exact UPN (beta endpoint).
- A string recognized as a UPN (see isValidUserPrincipalName) is matched exactly against userPrincipalName.
- Any other string, including guest #EXT# UPNs, is a displayName search ($search): it matches words in
  displayName that start with the search string (e.g.
'john' matches 'John Doe' and 'Mary Johnson', not 'Littlejohn').
Returns id, displayName, userPrincipalName, accountEnabled, mobilePhone, createdDateTime and
lastPasswordChangeDateTime, plus any -AdditionalProperties.

Requires scopes: User.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Find-GtUser "john"
```

Returns users with a word in displayName starting with 'john'.

### EXAMPLE 2
```
Find-GtUser "john.doe@zavainc.com"
```

Returns exact match for UPN.

## PARAMETERS

### -SearchString
Search string (3-99 chars).
Word-prefix match on displayName, exact match for UPN.

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
Extra properties to include in results (comma-separated, e.g.
"department,jobTitle").

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

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Find-GtUser.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Find-GtUser.md)

