function Get-GtDevice {
    <#
    .SYNOPSIS
    Get a device by object ID, device ID, or serial number.

    .DESCRIPTION
    Retrieves a single device from Entra ID.

    ById: Looks up the device by object ID (id) or device ID (deviceId).
    Both identifiers are matched in a single query, so either can be supplied.

    BySerialNumber: Entra ID devices do not expose a serial number, so the serial is first
    resolved via Intune (deviceManagement/managedDevices) to its azureADDeviceId, which is then
    used for the Entra ID lookup. If multiple managed devices share the serial number, the most
    recently synced one is used and a warning is written.

    The output is enriched with additional data:
    - Includes registered owners (resolved as comma-separated userPrincipalNames)
    - Adds group membership names (memberOf displayNames)
    - Provides synthetic deviceModel property (manufacturer + model)
    - Excludes original manufacturer and model properties
    Throws if no device is found.

    Requires scopes: Device.Read.All.
    BySerialNumber additionally requires: DeviceManagementManagedDevices.Read.All.

    .PARAMETER InputObject
    Device object (with id or deviceId property), object ID (id), or device ID (deviceId).
    Accepts pipeline input.

    .PARAMETER SerialNumber
    Hardware serial number of an Intune managed device (exact match).
    The device must be linked to Entra ID (have an azureADDeviceId).

    .PARAMETER AdditionalProperties
    Comma-separated list of additional device properties to include in the response (no spaces).

    .EXAMPLE
    Get-GtDevice "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    Retrieves device by object ID or device ID.

    .EXAMPLE
    $device | Get-GtDevice
    Accepts device object from pipeline.

    .EXAMPLE
    Get-GtDevice -SerialNumber "5CG1234XYZ"
    Resolves the serial number via Intune and retrieves the corresponding Entra ID device.

    .EXAMPLE
    Get-GtDevice "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -AdditionalProperties "deviceOwnership,enrollmentProfileName"
    Includes additional device properties.

    .OUTPUTS
    Device object with enriched properties: id, deviceId, displayName, operatingSystem, registeredOwners (comma-separated), groupMembership (array), deviceModel (synthetic), and standard device properties (isManaged, isCompliant, etc.)

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Get-GtDevice.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'ById')]
        [Object]$InputObject,
        
        [Parameter(Mandatory, ParameterSetName = 'BySerialNumber')]
        [ValidateNotNullOrEmpty()]
        [String]$SerialNumber,

        [Parameter(Mandatory = $false)]
        [ValidatePattern("^[a-z0-9,]+$")]
        [String]$AdditionalProperties
    )
    process {

        if ( $PSCmdlet.ParameterSetName -eq 'BySerialNumber' ) {
            Write-GtVerbose "Resolving serial number via Intune: $SerialNumber"
            $device = @(Invoke-GtGraphRequest -ResourcePath "deviceManagement/managedDevices" -Filter "serialNumber eq '$SerialNumber'" -Select "azureADDeviceId,lastSyncDateTime" -Verbose:$false |
                Where-Object { (isValidGuid $_.azureADDeviceId) } | Sort-Object lastSyncDateTime -Descending)
            if ( -not $device ) { throw "No Entra-linked Intune device found with serial number '$SerialNumber'." }
            if ( $device.Count -gt 1 ) { Write-Warning "$($device.Count) managed devices share serial '$SerialNumber'; using most recently synced." }
            $id = $device[0].azureADDeviceId
        }
        else { 
            $id = $null
            if ( $InputObject -is [string] ) { $id = $InputObject }
            elseif ( $InputObject.PSObject.Properties['id'] ) { $id = $InputObject.id }
            elseif ( $InputObject.PSObject.Properties['deviceId'] ) { $id = $InputObject.deviceId }
            if ( -not ($id | isValidGuid) ) { throw "objectId or deviceId is required ($id)" }
        }
        
        $queryParams = @{}
        $queryParams.select = "id,deviceId,displayName,operatingSystem,manufacturer,model,operatingSystemVersion,accountEnabled,approximateLastSignInDateTime,createdDateTime,isManaged,isCompliant,profileType,registrationDateTime,trustType,enrollmentType,managementType"
        if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }
        $queryParams.resourcePath = "devices"
        $queryParams.filter = "id eq '$id' or deviceId eq '$id'"
        $queryParams.expand = "memberOf(`$select=displayName)"
        $queryParams.verbose = $false

        Write-GtVerbose "Looking up device by id or deviceId: $id"
        try {
            $response = Invoke-GtGraphRequest @queryParams
            if ( !$response ) { throw "Device with identifier '$id' not found." }
            
            $owners = Invoke-GtGraphRequest -ResourcePath "devices/$($response.id)/registeredOwners" -Select "userPrincipalName" -Verbose:$false | Select-Object -ExpandProperty userPrincipalName
            return ($response | Select-Object *, @{N="registeredOwners";Expression={$owners -join ","}}, @{N="groupMembership";Expression={$_.memberOf.displayName}}, @{N="deviceModel";Expression={$_.manufacturer + ' ' + $_.model}} -ExcludeProperty memberOf,manufacturer,model )
        }
        catch { throw $_ }
    }
}