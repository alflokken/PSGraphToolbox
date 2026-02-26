function Get-GtUserAuthenticationMethods {
    <#
    .SYNOPSIS
    Get authentication methods for a user.

    .DESCRIPTION
    Retrieves registered authentication methods for a user.
    Supports filtering by method type (fido2, authenticator, etc.).

    Requires scopes: UserAuthenticationMethod.Read.All.

    .PARAMETER inputObject
    User object, UPN, or object ID.

    .PARAMETER methodType
    Filter by method type. Defaults to 'methods' (all).

    .EXAMPLE
    Get-GtUserAuthenticationMethods "user@zavainc.com"

    .EXAMPLE
    "user@zavainc.com" | authMethods -methodType fido2Methods

    .OUTPUTS
    Object containing array of authentication methods for the user.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserAuthenticationMethods.md
    #>
    [Alias('authMethods')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("fido2Methods","microsoftAuthenticatorMethods","emailMethods","passwordMethods","phoneMethods","platformCredentialMethods","softwareOathMethods","temporaryAccessPassMethods","windowsHelloForBusinessMethods","methods")]
        [String]$MethodType = "methods"
    )
    process {
        $id = idFromInputObject -inputObject $InputObject | Select-Object -ExpandProperty id
        try { $response = Invoke-GtGraphRequest -resourcePath "users/$id/authentication/$MethodType" -apiVersion beta }
        catch { throw $_ }
        return $response
    }
}