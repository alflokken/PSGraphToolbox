function Get-GtDevice {
    <#
    .SYNOPSIS
    Get a device by object ID or device ID.

    .DESCRIPTION
    Retrieves a single device from Entra ID by object ID (id) or device ID (deviceId).
    Automatically detects which identifier type is provided.
    
    The output is enriched with additional data:
    - Includes registered owners (resolved as comma-separated userPrincipalNames)
    - Adds group membership names
    - Provides synthetic deviceModel property (manufacturer + model)
    - Excludes original manufacturer and model properties

    Requires scopes: Device.Read.All.

    .PARAMETER InputObject
    Device object, object ID (id), or device ID (deviceId).

    .PARAMETER AdditionalProperties
    Additional properties to include in the response.

    .EXAMPLE
    Get-GtDevice "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    Retrieves device by object ID or device ID.

    .EXAMPLE
    $device | Get-GtDevice
    Accepts device object from pipeline.

    .EXAMPLE
    Get-GtDevice "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -AdditionalProperties "manufacturer,model"
    Includes additional device properties.

    .OUTPUTS
    Device object with enriched properties: id, deviceId, displayName, operatingSystem, registeredOwners (comma-separated), groupMembership (array), deviceModel (synthetic), and standard device properties (isManaged, isCompliant, etc.)

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Get-GtDevice.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,
        [Parameter(Mandatory = $false)][ValidatePattern("[a-z0-9,]")]
        [String]$AdditionalProperties
    )
    process {

        $id = $null
        if ( $InputObject -is [string] ) { $id = $InputObject }
        elseif ( $InputObject.PSObject.Properties['id'] ) { $id = $InputObject.id }
        elseif ( $InputObject.PSObject.Properties['deviceId'] ) { $id = $InputObject.deviceId }
        if ( -not ($id | isValidGuid) ) { throw "objectId or deviceId is required ($id)" }

        $queryParams = @{}
        $queryParams.select = "id,deviceId,displayName,operatingSystem,manufacturer,model,operatingSystemVersion,accountEnabled,approximateLastSignInDateTime,createdDateTime,isManaged,isCompliant,profileType,registrationDateTime,trustType,enrollmentType,managementType"
        if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }
        $queryParams.resourcePath = "devices"
        $queryParams.filter = "id eq '$id' or deviceId eq '$id'"
        $queryParams.expand = "memberOf(`$select=displayName)"

        Write-Verbose "Looking up device by id or deviceId: $id"
        try {
            $response = Invoke-GtGraphRequest @queryParams
            if ( !$response ) { throw "Device with identifier '$id' not found." }
            
            $owners = Invoke-GtGraphRequest -ResourcePath "devices/$($response.id)/registeredOwners" -Select "userPrincipalName" | Select-Object -ExpandProperty userPrincipalName
            return ($response | Select-Object *, @{N="registeredOwners";Expression={$owners -join ","}}, @{N="groupMembership";Expression={$_.memberOf.displayName}}, @{N="deviceModel";Expression={$_.manufacturer + ' ' + $_.model}} -ExcludeProperty memberOf,manufacturer,model )
        }
        catch { throw $_ }
    }
}
