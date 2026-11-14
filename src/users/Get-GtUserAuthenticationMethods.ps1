function Get-GtUserAuthenticationMethods {
    <#
    .SYNOPSIS
    Get authentication methods for a user.

    .DESCRIPTION
    Retrieves registered authentication methods for a user (beta endpoint).
    Supports filtering by method type (fido2Methods, microsoftAuthenticatorMethods, etc.).

    Requires scopes: UserAuthenticationMethod.Read.All.

    .PARAMETER inputObject
    User object, UPN, or object ID. Accepts pipeline input.

    .PARAMETER methodType
    Method type to return. Valid values: fido2Methods, microsoftAuthenticatorMethods, emailMethods, passwordMethods,
    phoneMethods, platformCredentialMethods, softwareOathMethods, temporaryAccessPassMethods,
    windowsHelloForBusinessMethods, methods. Defaults to 'methods' (all registered methods).

    .EXAMPLE
    Get-GtUserAuthenticationMethods "user@zavainc.com"
    Returns all registered authentication methods for the user.

    .EXAMPLE
    "user@zavainc.com" | authMethods -methodType fido2Methods
    Returns only the user's FIDO2 security keys.

    .OUTPUTS
    Array of authentication method objects. With 'methods', each object includes @odata.type identifying the method type.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Get-GtUserAuthenticationMethods.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("fido2Methods","microsoftAuthenticatorMethods","emailMethods","passwordMethods","phoneMethods","platformCredentialMethods","softwareOathMethods","temporaryAccessPassMethods","windowsHelloForBusinessMethods","methods")]
        [String]$MethodType = "methods"
    )
    process {
        $id = Get-IdFromInputObject -inputObject $InputObject | Select-Object -ExpandProperty id
        try { $response = Invoke-GtGraphRequest -resourcePath "users/$id/authentication/$MethodType" -apiVersion beta }
        catch { throw $_ }
        return $response
    }
}