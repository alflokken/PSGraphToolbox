function Get-GtAppCredentialReport {
    <#
    .SYNOPSIS
    Get application registration credentials with expiry information.

    .DESCRIPTION
    Retrieves all application registrations with their associated credentials
    (client secrets and certificates). Provides expiry tracking.
    
    Flattens credential arrays to show one row per credential with:
    - Application display name and app ID
    - Credential type ("Password (Client Secret)" or "Key (Certificate)")
    - Key/secret display name
    - Start/end dates and days until expiry
    - Application owners (display names, '; '-separated)
    Results are sorted by daysUntilExpiry (expired and soonest-expiring first).

    For SAML signing certificates on service principals, use Get-GtSamlCertificateReport.
    Federated identity credentials (workload identity federation) are not included.

    Requires scopes: Application.Read.All.

    .PARAMETER IncludeExpired
    Include expired credentials in the report. Defaults to $true.

    .PARAMETER outputType
    Output format: PSObject or html. Defaults to html.

    .EXAMPLE
    Get-GtAppCredentialReport
    Generates HTML report of all application credentials.

    .EXAMPLE
    Get-GtAppCredentialReport -IncludeExpired:$false -outputType PSObject
    Returns only active (non-expired) credentials as objects.

    .OUTPUTS
    PSObject mode: array of credential objects with appDisplayName, appId, credentialType, keyId, credentialDisplayName,
    startDateTime, endDateTime, daysUntilExpiry, isExpired, appOwners.
    html mode: nothing is returned. The report is written to .\PSGraphToolbox_ApplicationCredentials_<yyyyMMdd_HHmmss>.html
    in the current directory and opened in the default browser.

    .NOTES
    Renamed from Get-GtApplicationCredentialReport in v2.0.0.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtAppCredentialReport.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$IncludeExpired = $true,
        
        [Parameter()]
        [ValidateSet("PSObject", "html")]
        [string]$outputType = "html"
    )

    $results = @()
    $now = Get-Date

    # Credential type mapping
    $credentialTypes = @(
        @{ Property = "passwordCredentials"; Label = "Password (Client Secret)" }
        @{ Property = "keyCredentials";      Label = "Key (Certificate)" }
    )

    Write-GtVerbose "Retrieving application credentials"
    $apps = Invoke-GtGraphRequest -resourcePath "applications" -select "id,appId,displayName,keyCredentials,passwordCredentials" -expand "owners(`$select=displayName)" -PageLimit 999 -Verbose:$false

    Write-GtVerbose "Processing $($apps.Count) applications"
    foreach ( $app in $apps ) {
        foreach ( $credType in $credentialTypes ) {
            $credentials = $app.($credType.Property)
            if ( -not $credentials ) { continue }

            foreach ( $cred in $credentials ) {

                $endDate = [DateTime]$cred.endDateTime
                [int]$daysRemaining = ($endDate - $now).Days
                $isExpired = $endDate -lt $now
                
                $obj = New-Object -TypeName PSObject
                    $obj | Add-Member -NotePropertyName appDisplayName -NotePropertyValue $app.displayName
                    $obj | Add-Member -NotePropertyName appId -NotePropertyValue $app.appId
                    $obj | Add-Member -NotePropertyName credentialType -NotePropertyValue $credType.Label
                    $obj | Add-Member -NotePropertyName keyId -NotePropertyValue $cred.keyId
                    $obj | Add-Member -NotePropertyName credentialDisplayName -NotePropertyValue $cred.displayName
                    $obj | Add-Member -NotePropertyName startDateTime -NotePropertyValue $cred.startDateTime
                    $obj | Add-Member -NotePropertyName endDateTime -NotePropertyValue $cred.endDateTime
                    $obj | Add-Member -NotePropertyName daysUntilExpiry -NotePropertyValue $daysRemaining
                    $obj | Add-Member -NotePropertyName isExpired -NotePropertyValue $isExpired
                    $obj | Add-Member -NotePropertyName appOwners -NotePropertyValue ( ($app.owners | ForEach-Object { $_.displayName }) -join "; " )
                $results += $obj
            }
        }
    }

    # Apply filters
    if ( -not $IncludeExpired ) {
        Write-GtVerbose "Filtering out expired credentials"
        $results = $results | Where-Object { -not $_.isExpired }
    }

    $results = $results | Sort-Object daysUntilExpiry
    Write-GtVerbose "Found $($results.Count) credentials"

    if ( $outputType -eq "html" ) { $results | Export-GtHtmlReport -ReportTitle "Application Credentials" -path ".\PSGraphToolbox_ApplicationCredentials_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $results }
}