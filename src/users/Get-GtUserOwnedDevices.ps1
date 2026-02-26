function Get-GtUserOwnedDevices {
    <#
    .SYNOPSIS
    Get devices owned by a user.

    .DESCRIPTION
    Retrieves devices registered to a user in Entra ID.
    Returns comprehensive device details including:
    - Device properties (displayName, deviceId, operatingSystem, etc.)
    - Enrollment and management status (isManaged, isCompliant, enrollmentType)
    - Device registration date and last sign-in timestamp
    Results are sorted by approximate last sign-in (most recent first).

    Requires scopes: User.Read.All, Device.Read.All.

    .PARAMETER inputObject
    User object, UPN, or object ID.

    .EXAMPLE
    Get-GtUserOwnedDevices "user@zavainc.com"

    .EXAMPLE
    "user@zavainc.com" | ownedDevices

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserOwnedDevices.md
    #>
    [Alias('ownedDevices')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject
    )
    process {
        $id = idFromInputObject -inputObject $InputObject | Select-Object -ExpandProperty id
        try { $response = Invoke-GtGraphRequest -resourcePath "users/$id/ownedDevices" -apiVersion "v1.0" -select "displayName,deviceId,id,operatingSystem,operatingSystemVersion,accountEnabled,approximateLastSignInDateTime,createdDateTime,isManaged,isCompliant,profileType,registrationDate,trustType,enrollmentType,managementType" -orderBy "approximateLastSignInDateTime desc" -additionalHeaders @{ ConsistencyLevel = "eventual" } }
        catch { throw $_ }
        return $response | Sort-Object approximateLastSignInDateTime -Descending | Select-Object displayName,deviceId,id,operatingSystem,operatingSystemVersion,accountEnabled,approximateLastSignInDateTime,createdDateTime,isManaged,isCompliant,profileType,registrationDate,trustType,enrollmentType,managementType
    }
}