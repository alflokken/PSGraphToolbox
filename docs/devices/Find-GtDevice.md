---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Find-GtDevice.md
schema: 2.0.0
---

# Find-GtDevice

## SYNOPSIS
Search for devices by displayName.

## SYNTAX

```
Find-GtDevice [-SearchString] <String> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
Searches Entra ID devices by displayName ($search): matches words in displayName that start with the search string.
Returns basic device properties, sorted by createdDateTime (newest first).

Requires scopes: Device.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Find-GtDevice "DESKTOP"
```

Searches for devices with a word in displayName starting with 'DESKTOP'.

### EXAMPLE 2
```
Find-GtDevice "WIN" -AdditionalProperties "deviceOwnership,enrollmentProfileName"
```

Includes additional device properties.

## PARAMETERS

### -SearchString
The search string (3-99 chars) to match against device displayName.

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
Additional comma-separated device properties to include in the response.

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

### Array of device objects with id, deviceId, displayName, operatingSystem, operatingSystemVersion, accountEnabled,
### approximateLastSignInDateTime, createdDateTime, isManaged, isCompliant, profileType, registrationDateTime, trustType,
### enrollmentType, managementType, any -AdditionalProperties, and a synthetic deviceModel property
### (manufacturer + model; the original manufacturer and model properties are removed).
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Find-GtDevice.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Find-GtDevice.md)

