function Get-GtUserSignIns {
    <#
    .SYNOPSIS
    Get sign-in logs for a user.

    .DESCRIPTION
    Retrieves sign-in logs from Entra ID for a specific user.
    Includes authentication details, location, and status.

    Requires scopes: AuditLog.Read.All.

    .PARAMETER inputObject
    User object, UPN, or object ID.

    .PARAMETER startDate
    Start date for the query. Defaults to today 05:00.

    .PARAMETER endDate
    End date for the query. Defaults to now.

    .PARAMETER raw
    Return raw sign-in log objects without transformation/flattening.

    .OUTPUTS
    Array of sign-in log objects (raw or transformed). When not raw, output includes:
    - dateTime: Converted to local time
    - status: Mapped to "Success", "Interrupted", or "Failed"
    - authMethod_0, authMethod_1: Flattened authentication method details
    - device: Includes display name and device ID
    - correlationId: Short form (last segment only)

    .EXAMPLE
    Get-GtUserSignIns "user@zavainc.com"

    .EXAMPLE
    "user@zavainc.com" | signInLogs -startDate (Get-Date).AddDays(-7)

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/auditLogs/Get-GtUserSignIns.md
    #>
    [Alias('signInLogs')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$inputObject,
        [datetime]$startDate = (Get-Date 05:00),
        [datetime]$endDate = (Get-Date),
        [switch]$raw
    )
    process {

        if ( -not $inputObject ) { throw "Input object is null or empty." }
        # determine identifier
        if ( $inputObject -is [string] ) { $id = $inputObject }
        elseif ( $inputObject.PSObject.Properties['id'] ) { $id = $inputObject.id }
        elseif ($inputObject.PSObject.Properties['userPrincipalName']) { $id = $inputObject.userPrincipalName }
        else { throw "Unsupported input. Must be string or object with 'id' or 'userPrincipalName'." }
        
        try {
            if ( -not (isValidGuid $id) ) {
                Write-Debug "Resolving user '$id' to object ID..."
                $id = Invoke-GtGraphRequest -resourcePath "users/$id" -select "id" -errorAction SilentlyContinue | select -ExpandProperty id
                if ( -not $id ) { throw "User not found" }
            }
            [string]$startDateString = get-date ($startDate.ToUniversalTime()) -UFormat "%Y-%m-%dT%H:%M:%SZ"
            [string]$endDateString = get-date ($endDate.ToUniversalTime()) -UFormat "%Y-%m-%dT%H:%M:%SZ"
            $signInLogs = Invoke-GtGraphRequest -resourcePath "auditLogs/signIns" -filter "userId eq '$id' and createdDateTime ge $startDateString and createdDateTime le $endDateString" -top 999 -orderBy "createdDateTime desc" -apiVersion beta # beta required for authenticationDetails
            if ( $raw ) { return $signInLogs }
        }
        catch {
            throw $_
        }

        # filter and flatten
        return $signInLogs  | Select-Object @(
            @{ Name = "dateTime";           Expression = { (Get-Date $_.createdDateTime).ToLocalTime() } }
            @{ Name = "correlationId";      Expression = { ($_.correlationId -split "-")[-1] } }
            @{ Name = "userPrincipalName";  Expression = { $_.userPrincipalName } }
            @{ Name = "status";             Expression = { 
                $interruptCodes = @(50076, 50079, 50097, 50125, 50129, 50140, 50158, 50201, 50207) # source: https://cloudbrothers.info/en/entra-id-azure-ad-signin-errors/
                if ($_.status.errorCode -eq 0) { "Success" }
                elseif ($interruptCodes -contains $_.status.errorCode) { "Interrupted" }
                else { "Failed" }
            } }
            @{ Name = "application";        Expression = { $_.appDisplayName } }
            @{ Name = "authMethod_0";       Expression = { 
                if ($_.authenticationDetails.Count -ge 1) {
                    $prefix = if ($_.authenticationDetails[0].succeeded -eq $false -and $_.authenticationDetails[0].authenticationStepResultDetail -ne "MFA successfully completed" ) { "FAILED: " } else { "" }
                    "$prefix$($_.authenticationDetails[0].authenticationMethod)"
                }
            }}
            @{ Name = "authMethod_1";       Expression = { 
                if ($_.authenticationDetails.Count -gt 1) {
                    # beta endpoint authenticationDetail succeeded-value on text message is unreliable (at best..)
                    if ($_.authenticationDetails[1].succeeded -eq $false -and $_.authenticationDetails[1].authenticationStepResultDetail -ne "MFA successfully completed" ) { $prefix = "FAILED: " } 
                    else { $prefix = "" }
                    
                    $method = if ($_.authenticationDetails[1].authenticationMethod) { 
                        $_.authenticationDetails[1].authenticationMethod 
                    } else { 
                        $_.authenticationDetails[1].authenticationStepResultDetail 
                    }
                    "$prefix$method"
                }
            }}
            @{ Name = "ipAddress";          Expression = { $_.ipAddress } }
            @{ Name = "device";             Expression = { 
                [string]$deviceInfo = $null
                if ( $_.deviceDetail.deviceId ) { 
                    $deviceInfo += $_.deviceDetail.displayName
                    $deviceInfo += " ($((($_.deviceDetail.deviceId -split "-")[-1])))"
                }
                $deviceInfo
            } }
            @{ Name = "client";             Expression = { 
                if ($_.clientAppUsed -eq "Mobile apps and desktop clients") { "Native App" }
                else { $_.clientAppUsed }
            }}
            @{ Name = "browser";            Expression = { "$($_.deviceDetail.browser) (on $($_.deviceDetail.operatingSystem))" } }
            @{ Name = "compliantDevice";    Expression = { $_.deviceDetail.isCompliant } }
            @{ Name = "successfulCAPs";     Expression = {
                $caps = $_.appliedConditionalAccessPolicies | Where-Object { $_.result -eq "success" }
                ($caps | ForEach-Object { $_.displayName -replace "CA([0-9]+)\s+.*", 'CA$1' }) -join ";"
            }}
            @{ Name = "failedCAPs";          Expression = {
                $caps = $_.appliedConditionalAccessPolicies | Where-Object { $_.result -eq "failure" }
                ($caps | ForEach-Object { $_.displayName -replace "CA([0-9]+)\s+.*", 'CA$1' }) -join ";"
            }}
            @{ Name = "resultType";          Expression = { $_.status.errorCode } }
        )
    }
}