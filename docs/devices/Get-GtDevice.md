---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Get-GtDevice.md
schema: 2.0.0
---

# Get-GtDevice

## SYNOPSIS
Get a device by object ID or device ID.

## SYNTAX

```
Get-GtDevice [-InputObject] <Object> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a single device from Entra ID by object ID (id) or device ID (deviceId).
Automatically detects which identifier type is provided.

The output is enriched with additional data:
- Includes registered owners (resolved as comma-separated userPrincipalNames)
- Adds group membership names
- Provides synthetic deviceModel property (manufacturer + model)
- Excludes original manufacturer and model properties

Requires scopes: Device.Read.All.

## EXAMPLES

### EXAMPLE 1
```
Get-GtDevice "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

Retrieves device by object ID or device ID.

### EXAMPLE 2
```
$device | Get-GtDevice
```

Accepts device object from pipeline.

### EXAMPLE 3
```
Get-GtDevice "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -AdditionalProperties "manufacturer,model"
```

Includes additional device properties.

## PARAMETERS

### -InputObject
Device object, object ID (id), or device ID (deviceId).

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

### -AdditionalProperties
Additional properties to include in the response.

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

### Device object with enriched properties: id, deviceId, displayName, operatingSystem, registeredOwners (comma-separated), groupMembership (array), deviceModel (synthetic), and standard device properties (isManaged, isCompliant, etc.)
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Get-GtDevice.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Get-GtDevice.md)

