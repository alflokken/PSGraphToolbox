function Get-GtUser {
    <#
    .SYNOPSIS
    Get a user by ID or UPN.

    .DESCRIPTION
    Retrieves a single user from Entra ID by object ID or UPN.
    Returns id, displayName, userPrincipalName, accountEnabled, mobilePhone, createdDateTime and
    lastPasswordChangeDateTime, plus any -AdditionalProperties. Display names are not accepted (use Find-GtUser).
    Throws if the user is not found.

    Requires scopes: User.Read.All.

    .PARAMETER inputObject
    User object (id/userPrincipalName), UPN, or object ID. Accepts pipeline input.
        
    .PARAMETER AdditionalProperties
    Extra properties to include in results (comma-separated, e.g. "department,jobTitle").

    .EXAMPLE
    Get-GtUser "user@zavainc.com"
    Returns the user with the default properties.

    .EXAMPLE
    "user@zavainc.com" | Get-GtUser -AdditionalProperties "department,jobTitle"
    Pipeline usage with extra properties.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUser.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,

        [Parameter(Mandatory = $false)]
        [ValidatePattern("^[a-z0-9,]+$")]
        [String]$AdditionalProperties
    )
    process {
        
        $id = Get-IdFromInputObject -inputObject $InputObject | Select-Object -ExpandProperty id

        $queryParams = @{}
        $queryParams.select = "id,displayName,userPrincipalName,accountEnabled,mobilePhone,createdDateTime,lastPasswordChangeDateTime"
        if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }
        $queryParams.resourcePath = "users/$id"
        
        try { $response = Invoke-GtGraphRequest @queryParams }
        catch { throw $_ }
        
        return $response
    }
}