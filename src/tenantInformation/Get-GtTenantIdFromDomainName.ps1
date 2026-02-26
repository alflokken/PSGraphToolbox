function Get-GtTenantIdFromDomainName {
    <#
    .SYNOPSIS
    Get tenant ID from a domain name.

    .DESCRIPTION
    Looks up the Entra ID tenant ID for a domain using the public
    OpenID Connect discovery endpoint. Works without authentication.

    .PARAMETER domainName
    Domain name to look up (e.g., "zavainc.com").

    .OUTPUTS
    PSObject with domainName and tenantId.

    .EXAMPLE
    Get-GtTenantIdFromDomainName "zavainc.com"
    Returns tenant ID for zavainc.com.

    .EXAMPLE
    "zavainc.com" | Get-GtTenantIdFromDomainName
    Pipeline input supported.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantIdFromDomainName.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$domainName
    )
    process {
        $tenantId = "NOT-FOUND"
        $responseObject = New-Object PSObject

        try { $tenantId = ((Invoke-RestMethod "https://login.windows.net/$domainName/.well-known/openid-configuration" -Method GET | Select-Object -ExpandProperty issuer) -split "/")[3]}
        catch { throw $_ }

        Add-Member -InputObject $responseObject -NotePropertyMembers @{
            domainName    = $domainName
            tenantId = $tenantId
        }

        return $responseObject
    }
}