function Get-GtSamlCertificateReport {
    <#
    .SYNOPSIS
    Get SAML signing certificates from service principals with expiry information.

    .DESCRIPTION
    Retrieves SAML/SSO signing certificates from enterprise applications (service principals with
    preferredSingleSignOnMode 'saml'). These are certificates used for SAML token signing, separate from app registration credentials.
    Certificates are de-duplicated by customKeyIdentifier (thumbprint), so each certificate appears once.
    Expired certificates are included. Results are sorted by daysUntilExpiry (expired and soonest-expiring first).

    For application registration credentials (secrets/certificates), use Get-GtAppCredentialReport.

    Requires scopes: Application.Read.All.

    .PARAMETER outputType
    Output format: PSObject or html. Defaults to html.

    .OUTPUTS
    PSObject mode: array of certificate objects with appDisplayName, appId, keyId, certificateName, startDateTime, endDateTime,
    daysUntilExpiry, isExpired, appOwners.
    html mode: nothing is returned. The report is written to .\PSGraphToolbox_SamlCertificates_<yyyyMMdd_HHmmss>.html
    in the current directory and opened in the default browser.

    .EXAMPLE
    Get-GtSamlCertificateReport
    Generates HTML report of all SAML signing certificates.

    .EXAMPLE
    Get-GtSamlCertificateReport -outputType PSObject | Where-Object { $_.daysUntilExpiry -lt 30 }
    Returns SAML certificates that expire within 30 days (or have expired).

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtSamlCertificateReport.md
    #>
    [CmdletBinding()]
    param(        
        [Parameter()][ValidateSet("PSObject", "html")]
        [string]$outputType = "html"
    )

    $results = @()
    $now = Get-Date

    Write-GtVerbose "Retrieving service principal SAML certificates"
    try { $spns = Invoke-GtGraphRequest -resourcePath "servicePrincipals" -select "id,appId,displayName,keyCredentials,preferredSingleSignOnMode" -filter "preferredSingleSignOnMode eq 'saml'" -expand "owners(`$select=displayName)" -Verbose:$false }
    catch { throw $_ }
    
    Write-GtVerbose "Found $($spns.Count) SAML-enabled service principals"
    foreach ($spn in $spns) {
        if (-not $spn.keyCredentials) { continue }

        foreach ( $cred in ($spn.keyCredentials | Sort-Object -unique customKeyIdentifier) ) {

            $endDate = [DateTime]$cred.endDateTime
            $daysRemaining = ($endDate - $now).Days
            $isExpired = $endDate -lt $now

            $obj = New-Object -TypeName PSObject
                $obj | Add-Member -NotePropertyName appDisplayName -NotePropertyValue $spn.displayName
                $obj | Add-Member -NotePropertyName appId -NotePropertyValue $spn.appId
                $obj | Add-Member -NotePropertyName keyId -NotePropertyValue $cred.keyId
                $obj | Add-Member -NotePropertyName certificateName -NotePropertyValue $cred.displayName
                $obj | Add-Member -NotePropertyName startDateTime -NotePropertyValue $cred.startDateTime
                $obj | Add-Member -NotePropertyName endDateTime -NotePropertyValue $cred.endDateTime
                $obj | Add-Member -NotePropertyName daysUntilExpiry -NotePropertyValue $daysRemaining
                $obj | Add-Member -NotePropertyName isExpired -NotePropertyValue $isExpired
                $obj | Add-Member -NotePropertyName appOwners -NotePropertyValue ( ($spn.owners | ForEach-Object { $_.displayName }) -join "; " )
            $results += $obj
        }
    }

    # Sort by expiry date (soonest first)
    $results = $results | Sort-Object daysUntilExpiry

    Write-GtVerbose "Found $($results.Count) SAML certificates"
    if ($outputType -eq "html") { $results | Export-GtHtmlReport -ReportTitle "SAML Signing Certificates" -path ".\PSGraphToolbox_SamlCertificates_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $results }
}
