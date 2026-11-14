function Get-GtDomains {
    <#
    .SYNOPSIS
    Get tenant domains with federation configuration.

    .DESCRIPTION
    Retrieves all domains registered in the tenant.

    Output properties depend on whether the tenant has federated domains:
    - No federated domains: id, authenticationType, isVerified
    - At least one federated domain: all domains (sorted by authenticationType) with id, authenticationType, isVerified, isRoot,
      fedDisplayname, fedSigningCert, fedNextSigningCert, fedServiceUrl, fedMfaBehavior.
      The fed* properties are populated only for federated root domains (from their federationConfiguration);
      signing certificates are shortened to their first and last 5 characters.

    Requires scopes: Domain.Read.All.

    .OUTPUTS
    Array of domain objects. Properties depend on the tenant's domain configuration (see description).

    .EXAMPLE
    Get-GtDomains
    Returns all tenant domains, with federation details for federated root domains.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/domains/Get-GtDomains.md
    #>
    $response = Invoke-GtGraphRequest -resourcePath "domains"
    # federated domains
    if ( $response | where { $_.authenticationType -eq "Federated" } ) {
        # expand
        $response = $response | Sort-Object authenticationType | Select-Object id, authenticationType, isVerified, isRoot, fedDisplayname, fedSigningCert, fedNextSigningCert, fedServiceUrl, fedMfaBehavior
        # enrich
        foreach ( $domain in ($response | where { $_.authenticationType -eq "Federated" -and $_.isRoot -eq $true}) ) {
            $fedConfig = Invoke-GtGraphRequest -resourcePath "domains/$($domain.id)/federationConfiguration"
            $domain.fedDisplayname = $fedConfig.displayName
            $domain.fedServiceUrl = $fedConfig.passiveSignInUri
            $domain.fedSigningCert = (($fedConfig.signingCertificate.ToCharArray() | select -first 5) -join '') + '...' + (($fedConfig.signingCertificate.ToCharArray() | select -last 5) -join '')
            $domain.fedMfaBehavior = $fedConfig.federatedIdpMfaBehavior
            if ( $fedConfig.nextSigningCertificate ) { $domain.fedNextSigningCert = (($fedConfig.nextsigningCertificate.ToCharArray() | select -first 5) -join '') + '...' + (($fedConfig.nextsigningCertificate.ToCharArray() | select -last 5) -join '') } 
        }
    }
    else { $response = $response | Select-Object id, authenticationType, isVerified }
    return $response
}