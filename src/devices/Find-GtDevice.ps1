function Find-GtDevice {
    <#
    .SYNOPSIS
    Search for devices by displayName.

    .DESCRIPTION
    Searches Entra ID devices by displayName ($search): matches words in displayName that start with the search string.
    Returns basic device properties, sorted by createdDateTime (newest first).

    Requires scopes: Device.Read.All.

    .PARAMETER SearchString
    The search string (3-99 chars) to match against device displayName.

    .PARAMETER AdditionalProperties
    Additional comma-separated device properties to include in the response.

    .EXAMPLE
    Find-GtDevice "DESKTOP"
    Searches for devices with a word in displayName starting with 'DESKTOP'.

    .EXAMPLE
    Find-GtDevice "WIN" -AdditionalProperties "deviceOwnership,enrollmentProfileName"
    Includes additional device properties.

    .OUTPUTS
    Array of device objects with id, deviceId, displayName, operatingSystem, operatingSystemVersion, accountEnabled,
    approximateLastSignInDateTime, createdDateTime, isManaged, isCompliant, profileType, registrationDateTime, trustType,
    enrollmentType, managementType, any -AdditionalProperties, and a synthetic deviceModel property
    (manufacturer + model; the original manufacturer and model properties are removed).

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/devices/Find-GtDevice.md
    #>
    [Alias('deviceSearch', 'searchDevice')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)][ValidateLength(3, 99)]
        [String]$SearchString,
        [Parameter(Mandatory = $false)][ValidatePattern("^[a-z0-9,]+$")]
        [String]$AdditionalProperties
    )

    $queryParams = @{}
    $queryParams.select = "id,deviceId,displayName,operatingSystem,operatingSystemVersion,accountEnabled,approximateLastSignInDateTime,createdDateTime,isManaged,isCompliant,profileType,registrationDateTime,trustType,enrollmentType,managementType,model,manufacturer"
    if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }
    $queryParams.resourcePath = "devices"
    $queryParams.search = "`"displayName:$SearchString`""
    $queryParams.orderBy = "createdDateTime desc"

    Write-GtVerbose "Searching devices with displayName containing: $SearchString"
    try { $response = Invoke-GtGraphRequest @queryParams -verbose:$false }
    catch { throw $_ }

    return $response | select *, @{N="deviceModel";Expression={$_.manufacturer + ' ' + $_.model}} -ExcludeProperty manufacturer,model
}
