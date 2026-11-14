---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Get-GtDevice.md
schema: 2.0.0
---

# Get-GtDevice

## SYNOPSIS
Get a device by object ID, device ID, or serial number.

## SYNTAX

### ById
```
Get-GtDevice [-InputObject] <Object> [-AdditionalProperties <String>] [<CommonParameters>]
```

### BySerialNumber
```
Get-GtDevice -SerialNumber <String> [-AdditionalProperties <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a single device from Entra ID.

ById: Looks up the device by object ID (id) or device ID (deviceId).
Both identifiers are matched in a single query, so either can be supplied.

BySerialNumber: Entra ID devices do not expose a serial number, so the serial is first
resolved via Intune (deviceManagement/managedDevices) to its azureADDeviceId, which is then
used for the Entra ID lookup.
If multiple managed devices share the serial number, the most
recently synced one is used and a warning is written.

The output is enriched with additional data:
- Includes registered owners (resolved as comma-separated userPrincipalNames)
- Adds group membership names (memberOf displayNames)
- Provides synthetic deviceModel property (manufacturer + model)
- Excludes original manufacturer and model properties
Throws if no device is found.

Requires scopes: Device.Read.All.
BySerialNumber additionally requires: DeviceManagementManagedDevices.Read.All.

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
Get-GtDevice -SerialNumber "5CG1234XYZ"
```

Resolves the serial number via Intune and retrieves the corresponding Entra ID device.

### EXAMPLE 4
```
Get-GtDevice "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -AdditionalProperties "deviceOwnership,enrollmentProfileName"
```

Includes additional device properties.

## PARAMETERS

### -InputObject
Device object (with id or deviceId property), object ID (id), or device ID (deviceId).
Accepts pipeline input.

```yaml
Type: Object
Parameter Sets: ById
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SerialNumber
Hardware serial number of an Intune managed device (exact match).
The device must be linked to Entra ID (have an azureADDeviceId).

```yaml
Type: String
Parameter Sets: BySerialNumber
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalProperties
Comma-separated list of additional device properties to include in the response (no spaces).

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

