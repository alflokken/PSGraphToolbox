function Find-GtUser {
    <#
    .SYNOPSIS
    Search Entra ID users by displayName or UPN.

    .DESCRIPTION
    Finds users by displayName or exact UPN (beta endpoint).
    - A string recognized as a UPN (see isValidUserPrincipalName) is matched exactly against userPrincipalName.
    - Any other string, including guest #EXT# UPNs, is a displayName search ($search): it matches words in
      displayName that start with the search string (e.g. 'john' matches 'John Doe' and 'Mary Johnson', not 'Littlejohn').
    Returns id, displayName, userPrincipalName, accountEnabled, mobilePhone, createdDateTime and
    lastPasswordChangeDateTime, plus any -AdditionalProperties.

    Requires scopes: User.Read.All.

    .PARAMETER SearchString
    Search string (3-99 chars). Word-prefix match on displayName, exact match for UPN.

    .PARAMETER AdditionalProperties
    Extra properties to include in results (comma-separated, e.g. "department,jobTitle").

    .EXAMPLE
    Find-GtUser "john"
    Returns users with a word in displayName starting with 'john'.

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
        [ValidatePattern("^[a-z0-9,]+$")]
        [String]$AdditionalProperties
    )
    
    $queryParams = @{}
    $queryParams.select = "id,displayName,userPrincipalName,accountEnabled,mobilePhone,createdDateTime,lastPasswordChangeDateTime"
    if ( $AdditionalProperties ) { $queryParams.select = "$($queryParams.select), $AdditionalProperties" }
    $queryParams.apiVersion = "beta"
    $queryParams.resourcePath = "users"
    if ( $SearchString | isValidUserPrincipalName ) { $queryParams.filter = "userPrincipalName eq '$SearchString'" }
    else { $queryParams.search = "`"displayName:$SearchString`""}

    Write-GtVerbose "Searching users with $($queryParams.search) $($queryParams.filter)"
    try { return Invoke-GtGraphRequest @queryParams -verbose:$false }
    catch { throw $_ }
    # todo if filter and no response, try search proxyAddresses
}