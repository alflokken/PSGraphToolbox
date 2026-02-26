function Get-FederationMetadataFromURL {
    <#
    .SYNOPSIS
        Parse SAML federation metadata from URL.

    .DESCRIPTION
        Retrieves and parses ADFS/SAML federation metadata XML, extracting
        key information like signing certificates, SSO URLs, and brand name.

    .PARAMETER metadataURL
        Full URL to the FederationMetadata.xml file.

    .OUTPUTS
        PSObject with:
        - FederationBrandName: Federation service display name
        - ActiveLogOnUri: POST binding SSO URL
        - X509SigningCertificate: Current signing certificate (base64)
        - X509NextSigningCertificate: Next signing certificate if published
        - LogOffUri, PassiveLogOnUri, MetadataExchangeUri: Additional endpoints

    .EXAMPLE
        Get-FederationMetadataFromURL "https://adfs.contoso.com/FederationMetadata/2007-06/FederationMetadata.xml"
        Parses federation metadata from ADFS server.
    #>
    param( [Parameter( Position=0, Mandatory=$true )][String]$metadataURL )
    # Retreive metadata from URL
    try { $Metadata = Invoke-RestMethod $metadataURL -ErrorAction Stop }
    catch { throw $_ }
    # Build object
    $Obj = New-Object -TypeName PSObject
    $Obj | Add-Member -TypeName NoteProperty -NotePropertyName FederationBrandName ($Metadata.EntityDescriptor.RoleDescriptor | Where-Object { $_.type -eq "fed:SecurityTokenServiceType" }).ServiceDisplayname
    $Obj | Add-Member -TypeName NoteProperty -NotePropertyName ActiveLogOnUri ($Metadata.EntityDescriptor.IDPSSODescriptor.SingleSignOnService | Where-Object { $_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" }).Location
    # If NextSigningCertificate is published.
    $signingCerts = $Metadata.EntityDescriptor.IDPSSODescriptor.KeyDescriptor | where { $_.Use -eq "signing" }
    if ( $signingCerts.count -ge 2 ) {
        $Obj | Add-Member -TypeName NoteProperty -NotePropertyName X509SigningCertificate ($SigningCerts | select -First 1).KeyInfo.X509Data.X509Certificate
        $Obj | Add-Member -TypeName NoteProperty -NotePropertyName X509NextSigningCertificate ($SigningCerts | select -Last 1).KeyInfo.X509Data.X509Certificate
    }
    else { $Obj | Add-Member -TypeName NoteProperty -NotePropertyName X509SigningCertificate ($SigningCerts | select -Last 1).KeyInfo.X509Data.X509Certificate }
    $Obj | Add-Member -TypeName NoteProperty -NotePropertyName LogOffUri $Obj.ActiveLogOnUri
    $Obj | Add-Member -TypeName NoteProperty -NotePropertyName MetadataExchangeUri ($Metadata.EntityDescriptor.RoleDescriptor | Where-Object { $_.type -eq "fed:SecurityTokenServiceType" }).SecurityTokenServiceEndpoint.EndpointReference.Metadata.Metadata.MetadataSection.MetadataReference.Address.'#text'
    $Obj | Add-Member -TypeName NoteProperty -NotePropertyName PassiveLogOnUri $Obj.ActiveLogOnUri
    return $Obj
}
# exporting cert
#$x509cert = [X509Certificate]::new([convert]::FromBase64String($fed.X509SigningCertificate))
#'-----BEGIN CERTIFICATE-----' | Out-File -FilePath .\certificate.cer;  
#$fed.X509SigningCertificate | Out-File -FilePath .\certificate.cer -Append;  
#'-----END CERTIFICATE-----' | Out-File -FilePath .\certificate.cer -Append;