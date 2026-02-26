function Get-GtSamlCertificateReport {
    <#
    .SYNOPSIS
    Get SAML signing certificates from service principals with expiry information.

    .DESCRIPTION
    Retrieves SAML/SSO signing certificates from enterprise applications (service principals).
    These are certificates used for SAML token signing, separate from app registration credentials.

    For application registration credentials (secrets/certificates), use Get-GtApplicationCredentialReport.

    Requires scopes: Application.Read.All.

    .PARAMETER IncludeExpired
    Include expired certificates in the report. Defaults to $true.

    .PARAMETER outputType
    Output format: PSObject or html. Defaults to html.

    .OUTPUTS
    Array of certificate objects (PSObject mode) or HTML report file path (html mode).
    Each object contains: appDisplayName, appId, keyId, certificateName, startDateTime, endDateTime, daysUntilExpiry, isExpired, appOwners.

    .EXAMPLE
    Get-GtSamlCertificateReport
    Generates HTML report of all SAML signing certificates.

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

    Write-Verbose "Retrieving service principal SAML certificates"
    try { $spns = Invoke-GtGraphRequest -resourcePath "servicePrincipals" -select "id,appId,displayName,keyCredentials,preferredSingleSignOnMode" -filter "preferredSingleSignOnMode eq 'saml'" -expand "owners(`$select=displayName)" -Verbose:$false }
    catch { throw $_ }
    
    Write-Verbose "Found $($spns.Count) SAML-enabled service principals"
    foreach ($spn in $spns) {
        if (-not $spn.keyCredentials) { continue }

        foreach ( $cred in ($spn.keyCredentials | Sort-Object -unique customKeyIdentifier) ) {

            $endDate = [DateTime]$cred.endDateTime
            $daysRemaining = ($endDate - $now).Days
            $isExpired = $daysRemaining -lt 0

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

    Write-Verbose "Found $($results.Count) SAML certificates"
    if ($outputType -eq "html") { $results | Export-GtHtmlReport -ReportTitle "SAML Signing Certificates" -path ".\PSGraphToolbox_SamlCertificates_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $results }
}
