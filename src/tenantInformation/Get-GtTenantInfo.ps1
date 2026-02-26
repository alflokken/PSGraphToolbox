function Get-GtTenantInfo {
    <#
    .SYNOPSIS
    Get tenant organization information.

    .DESCRIPTION
    Retrieves basic tenant information including display name, tenant ID, tenant type,
    domain configuration, and verification status.

    Requires scopes: Organization.Read.All, Domain.Read.All.

    .OUTPUTS
    PSObject with properties: tenantId, displayName, tenantType, countryCode, createdDateTime, 
    defaultDomain, initialDomain, verifiedDomainCount, domains (comma-separated).

    .EXAMPLE
    Get-GtTenantInfo
    Returns tenant organization details.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/tenantInformation/Get-GtTenantInfo.md
    #>
    [CmdletBinding()]
    param()

    # get organization info
    $org = Invoke-GtGraphRequest -resourcePath "organization" -select "id,displayName,verifiedDomains,tenantType,createdDateTime,countryLetterCode"
    
    # get domains
    $domains = Invoke-GtGraphRequest -resourcePath "domains" -select "id,isDefault,isInitial,isVerified"

    # build output
    $obj = New-Object -TypeName PSObject
    $obj | Add-Member -NotePropertyName tenantId -NotePropertyValue $org.id
    $obj | Add-Member -NotePropertyName displayName -NotePropertyValue $org.displayName
    $obj | Add-Member -NotePropertyName tenantType -NotePropertyValue $org.tenantType
    $obj | Add-Member -NotePropertyName countryCode -NotePropertyValue $org.countryLetterCode
    $obj | Add-Member -NotePropertyName createdDateTime -NotePropertyValue $org.createdDateTime
    $obj | Add-Member -NotePropertyName defaultDomain -NotePropertyValue (($domains | Where-Object { $_.isDefault }).id)
    $obj | Add-Member -NotePropertyName initialDomain -NotePropertyValue (($domains | Where-Object { $_.isInitial }).id)
    $obj | Add-Member -NotePropertyName verifiedDomainCount -NotePropertyValue ($domains | Where-Object { $_.isVerified }).Count
    $obj | Add-Member -NotePropertyName domains -NotePropertyValue ($domains.id -join ", ")
    
    return $obj
}
