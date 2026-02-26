function Get-GtApplicationCredentialReport {
    <#
    .SYNOPSIS
    Get application registration credentials with expiry information.

    .DESCRIPTION
    Retrieves all application registrations with their associated credentials
    (client secrets and certificates). Provides expiry tracking.
    
    Flattens credential arrays to show one row per credential with:
    - Application display name and app ID
    - Credential type (password/key)
    - Key/secret display name
    - Start/end dates and days until expiry

    For SAML signing certificates on service principals, use Get-GtSamlCertificateReport.

    Requires scopes: Application.Read.All.

    .PARAMETER IncludeExpired
    Include expired credentials in the report. Defaults to $true.

    .PARAMETER outputType
    Output format: PSObject or html. Defaults to html.

    .EXAMPLE
    Get-GtApplicationCredentialReport
    Generates HTML report of all application credentials.

    .EXAMPLE
    Get-GtApplicationCredentialReport -IncludeExpired:$false
    Shows only active (non-expired) credentials.

    .OUTPUTS
    Array of credential objects (PSObject mode) or HTML report file path (html mode).
    Each object contains: appDisplayName, appId, credentialType, keyId, credentialDisplayName, startDateTime, endDateTime, daysUntilExpiry, isExpired, appOwners.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtApplicationCredentialReport.md
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

    Write-Verbose "Retrieving application credentials"
    $apps = Invoke-GtGraphRequest -resourcePath "applications" -select "id,appId,displayName,keyCredentials,passwordCredentials" -expand "owners(`$select=displayName)" -Verbose:$false
    
    Write-Verbose "Processing $($apps.Count) applications"
    foreach ( $app in $apps ) {
        foreach ( $credType in $credentialTypes ) {
            $credentials = $app.($credType.Property)
            if ( -not $credentials ) { continue }

            foreach ( $cred in $credentials ) {

                $endDate = [DateTime]$cred.endDateTime
                [int]$daysRemaining = ($endDate - $now).Days
                $isExpired = $daysRemaining -lt 0
                
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
        Write-Verbose "Filtering out expired credentials"
        $results = $results | Where-Object { -not $_.isExpired }
    }

    $results = $results | Sort-Object daysUntilExpiry
    Write-Verbose "Found $($results.Count) credentials"

    if ( $outputType -eq "html" ) { $results | Export-GtHtmlReport -ReportTitle "Application Credentials" -path ".\PSGraphToolbox_ApplicationCredentials_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $results }
}
