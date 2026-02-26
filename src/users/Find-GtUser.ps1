function Find-GtUser {
    <#
    .SYNOPSIS
    Search Entra ID users by displayName or UPN.

    .DESCRIPTION
    Finds users by partial displayName or exact UPN. Returns basic properties. Supports extra properties via -AdditionalProperties. Requires User.Read.All.

    .PARAMETER SearchString
    Search string (min 3 chars). Partial match for displayName, exact for UPN.

    .PARAMETER AdditionalProperties
    Extra properties to include in results.

    .EXAMPLE
    Find-GtUser "john"
    Searches for users with 'john' in displayName.

    .EXAMPLE
    Find-GtUser "john.doe@zavainc.com"
    Returns exact match for UPN.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Find-GtUser.md
    #>
    [Alias('userSearch','searchUser')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)][ValidateLength(3,99)]
        [String]$SearchString,

        [Parameter(Mandatory = $false)]
        [ValidatePattern("[a-z0-9,]")]
        [String]$AdditionalProperties
    )
    
    $queryParams = @{}
    $queryParams.select = "id,displayName,userPrincipalName,accountEnabled,mobilePhone,createdDateTime,lastPasswordChangeDateTime"
    if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }
    $queryParams.apiVersion = "beta"
    $queryParams.resourcePath = "users"
    if ( $SearchString | isValidUserPrincipalName ) { $queryParams.filter = "userPrincipalName eq '$SearchString'" }
    else { $queryParams.search = "`"displayName:$SearchString`""}

    Write-Verbose "Searching users with $($queryParams.search) $($queryParams.filter)"
    try { return Invoke-GtGraphRequest @queryParams -verbose:$false }
    catch { throw $_ }
    # todo if filter and no response, try search proxyAddresses
}