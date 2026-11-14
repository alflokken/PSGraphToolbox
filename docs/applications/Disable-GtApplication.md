---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/applications/Disable-GtApplication.md
schema: 2.0.0
---

# Disable-GtApplication

## SYNOPSIS
Disable app registration and service principal.

## SYNTAX

```
Disable-GtApplication [-InputObject] <Object> [-WhatIf] [-Confirm <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Looks up the application registration and the service principal by appId and disables them:
- Application registration (only if it exists in this tenant): sets isDisabled = true (beta endpoint).
  This disables the app globally, in every tenant where it is used.
- Service principal (if it exists in this tenant): sets accountEnabled = false (this tenant only).
If neither is found, a warning is written and the input is skipped.
Unless -WhatIf is used or -Confirm is $false,
you are prompted to confirm (Y/N).
Status is written to the host; nothing is returned.

Requires scopes: Application.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
Find-GtServicePrincipal "MigrationWiz" | Disable-GtApplication -WhatIf
```

Previews which app registration and service principal would be disabled.

### EXAMPLE 2
```
Disable-GtApplication -InputObject "00000000-0000-0000-0000-000000000000" -Confirm $false
```

Disables the app registration and service principal for the appId without prompting.

## PARAMETERS

### -InputObject
Object with an appId property (e.g.
output from Find-GtServicePrincipal or Find-GtApplication), or an appId (GUID).
Object IDs and display names are not accepted.
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

### -WhatIf
Preview changes without making them.

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

### -Confirm
Prompt for confirmation.
Defaults to true.
Set to $false to skip the prompt.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None. Results are written to the host.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/applications/Disable-GtApplication.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/applications/Disable-GtApplication.md)

