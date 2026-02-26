function Get-GtTenantInformationByTenantId {
    <#
    .SYNOPSIS
    Get tenant information by tenant ID.

    .DESCRIPTION
    Retrieves basic tenant information (display name, default domain) 
    for any tenant by its ID. Uses beta API for cross-tenant lookup.

    Requires scopes: CrossTenantInformation.ReadBasic.All.

    .PARAMETER TenantId
    The tenant ID (GUID) to look up.

    .OUTPUTS
    PSObject with cross-tenant information: displayName, defaultDomain, federationBrandName, etc.

    .EXAMPLE
    Get-GtTenantInformationByTenantId "00000000-0000-0000-0000-000000000000"
    Returns tenant information for the specified ID.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantInformationByTenantId.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [guid]$tenantId
    )
    process { return Invoke-GtGraphRequest -resourcePath "tenantRelationships/findTenantInformationByTenantId(tenantId='$($tenantId)')" -apiVersion "beta" | Select-Object * -ExcludeProperty "@odata.context" }
}