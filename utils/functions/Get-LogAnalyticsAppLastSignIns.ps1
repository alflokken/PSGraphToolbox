function Get-LogAnalyticsAppLastSignInDateTime {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,

        [Parameter(Mandatory = $true)]
        [String]$WorkspaceId
    )
    process {
        # app object (appId property) or appId string
        $appId = if ( $InputObject.appId ) { $InputObject.appId } else { $InputObject }
        $appId = Get-IdFromInputObject -inputObject $appId -objectIdOnly | Select-Object -ExpandProperty id

        $userQuery = @"
union
    (SigninLogs | where IsInteractive == true),
    AADNonInteractiveUserSignInLogs
| where AppId == "$appId" and ResultType == "0"
| summarize lastSignIn = max(CreatedDateTime)
"@
        $spnQuery = @"
AADServicePrincipalSignInLogs
| where AppId == "$appId" and ResultType == "0"
| summarize lastSignIn = max(CreatedDateTime)
"@
        $lastUser = (Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $userQuery).Results.lastSignIn
        $lastSpn  = (Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $spnQuery).Results.lastSignIn

        [pscustomobject]@{
            appId               = $appId
            lastDelegatedSignIn = if ( $lastUser ) { $lastUser } else { 'null' }
            lastAppOnlySignIn   = if ( $lastSpn ) { $lastSpn } else { 'null' }
        }
    }
}