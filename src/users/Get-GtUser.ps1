function Get-GtUser {
    <#
    .SYNOPSIS
    Get a user by ID or UPN.

    .DESCRIPTION
    Retrieves a single user from Entra ID by object ID or UPN.

    Requires scopes: User.Read.All.

    .PARAMETER inputObject
    User object, UPN, or object ID.
        
    .PARAMETER AdditionalProperties
    Extra properties to include in results.

    .EXAMPLE
    Get-GtUser "user@zavainc.com"

    .EXAMPLE
    "user@zavainc.com" | Get-GtUser

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUser.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,

        [Parameter(Mandatory = $false)]
        [ValidatePattern("[a-z0-9,]")]
        [String]$AdditionalProperties
    )
    process {
        
        $id = idFromInputObject -inputObject $InputObject | Select-Object -ExpandProperty id

        $queryParams = @{}
        $queryParams.select = "id,displayName,userPrincipalName,accountEnabled,mobilePhone,createdDateTime,lastPasswordChangeDateTime"
        if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }
        $queryParams.resourcePath = "users/$id"
        
        try { $response = Invoke-GtGraphRequest @queryParams }
        catch { throw $_ }
        
        return $response
    }
}