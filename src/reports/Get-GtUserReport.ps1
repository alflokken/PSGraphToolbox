function Get-GtUserReport {
    <#
    .SYNOPSIS
    Get a flat report of users or guests with sign-in activity.

    .DESCRIPTION
    Retrieves users or guests from Entra ID (beta endpoint, required for signInActivity) with key governance data:
    - Account status (only enabled accounts, unless -IncludeDisabledAccounts is used)
    - Sign-in activity (last successful, last interactive and last non-interactive sign-in, days since last successful sign-in)
    - Entra ID P1/P2 license (IsAadLicensed)
    - Members: sync status (cloud-only vs hybrid), manager and organization details
    - Guests: invitation state, guest domain and sponsors
    - State, based on the last successful sign-in:
      active, inactive (no successful sign-in within -MonthsInactive months), never signed in,
      recentlyInvited (guest with a pending invitation changed within -MonthsInactive months), disabled

    Requires scopes: User.Read.All, AuditLog.Read.All (for signInActivity).

    .PARAMETER UserType
    Filter by user type: Member or Guest. Defaults to Member.

    .PARAMETER MonthsInactive
    Number of months without successful sign-in to flag as inactive. Defaults to 3.

    .PARAMETER IncludeDisabledAccounts
    Include disabled accounts (state 'disabled'). By default only enabled accounts are returned.

    .PARAMETER outputType
    Output format: PSObject or html. Defaults to html.

    .OUTPUTS
    PSObject mode: array of flat user objects with id, displayName, userPrincipalName, accountEnabled, userType, state, IsAadLicensed,
    daysSinceSignIn, lastSuccessfulSignIn, lastInteractiveSignIn, lastNonInteractiveSignIn, createdDateTime, plus
    - Member: onPremisesSyncEnabled, manager (UPN), department, jobTitle, companyName, country
    - Guest: externalUserState, externalUserStateChangeDateTime, guestDomain, sponsors (UPN or displayName)
    html mode: nothing is returned. The report (without id) is written to .\PSGraphToolbox_UserReport_<yyyyMMdd_HHmmss>.html
    in the current directory and opened in the default browser.

    .EXAMPLE
    Get-GtUserReport
    Returns all enabled member users as HTML report.

    .EXAMPLE
    Get-GtUserReport -UserType Guest -MonthsInactive 12
    Returns enabled guest users, flagging those without a successful sign-in for 12+ months as inactive.

    .EXAMPLE
    Get-GtUserReport -IncludeDisabledAccounts -outputType PSObject
    Returns all member users, including disabled accounts, as PSObject for further processing.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtUserReport.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Member", "Guest")] #todo agentUsers
        [string]$UserType = "Member",

        [Parameter()]
        [int]$MonthsInactive = 3,

        [Parameter()]
        [switch]$IncludeDisabledAccounts, #todo

        [Parameter()]
        [ValidateSet("PSObject", "html")]
        [string]$outputType = "html"
    )
    # build query params
    $userParams = @{
        resourcePath = "users"
        apiVersion   = "beta" # using beta to access signInActivity property
        select       = "id,userPrincipalName,displayName,accountEnabled,assignedPlans,userType,createdDateTime,signInActivity,onPremisesSyncEnabled,onPremisesLastSyncDateTime,department,companyName,jobTitle,country,city"
        expand       = "manager(`$select=userPrincipalName)"
        filter       = "userType eq '$UserType' and accountEnabled eq true"
        verbose      = $false
        PageLimit    = 999
    }
    if ( $IncludeDisabledAccounts ) { $userParams['filter'] = $userParams['filter'].Replace(' and accountEnabled eq true', '') }
    if ( $UserType -eq "Guest" ) { $userParams['select'] += ",externalUserState,externalUserStateChangeDateTime" }

    Write-GtVerbose "Retrieving $UserType users..."
    $users = Invoke-GtGraphRequest @userParams

    if ( $UserType -eq "Guest" ) {
        Write-GtVerbose "Retrieving guest sponsors..."
        $sponsorHt = Invoke-GtGraphRequest -ResourcePath "users" -Select "id" -Filter "userType eq 'Guest'" -Expand "sponsors(`$select=userPrincipalName,displayName)" -Verbose:$false | ConvertTo-HashTable
    }

    # calculate inactive threshold
    $inactiveDate = (Get-Date).AddMonths(-$MonthsInactive)

    # build flat report
    Write-GtVerbose "processing $($users.Count) users"
    $report = foreach ($user in $users) {
        
        # determine state based on lastSuccessfulSignInDateTime (most reliable)
        $state = "active"
        if ( -not $user.accountEnabled ) { $state = "disabled" }
        elseif ( -not $user.signInActivity.lastSuccessfulSignInDateTime ) { 
            $state = "never signed in" 
            if ( $user.externalUserState -eq "PendingAcceptance" -and $User.externalUserStateChangeDateTime -gt (Get-Date).AddMonths(-$MonthsInactive)) { $state = "recentlyInvited" }
        }
        elseif ( $user.signInActivity.lastSuccessfulSignInDateTime -lt $inactiveDate ) { $state = "inactive" }
        
        $hasP1OrP2 = $user.assignedPlans | where { $_.capabilityStatus -eq "Enabled" -and ($_.servicePlanId -match "eec0eb4f-6444-4f95-aba0-50c24d67f998|41781fb2-bc02-4b7c-bd55-b576c07bb09d") }
        if ( $user.userType -eq "Guest" ) {
            $sponsors = if ( $sponsorHt[$user.id].sponsors.userPrincipalName ) { $sponsorHt[$user.id].sponsors.userPrincipalName } else { $sponsorHt[$user.id].sponsors.displayName }
            $guestDomain = if ( $user.userType -eq "Guest" ) { ($user.userPrincipalName -replace "#EXT#.*" -replace ".*[_]") } else { $null }
        }

        $daysSinceSignIn = if ( $user.signInActivity.lastSuccessfulSignInDateTime ) { [int]((Get-Date) - (Get-Date $user.signInActivity.lastSuccessfulSignInDateTime)).TotalDays } else { $null }

        # build flat object
        $obj = New-Object -TypeName PSObject
        if ( $outputType -eq "PSObject" ) { $obj | Add-Member -NotePropertyName id -NotePropertyValue $user.id }
        $obj | Add-Member -NotePropertyName displayName -NotePropertyValue $user.displayName
        $obj | Add-Member -NotePropertyName userPrincipalName -NotePropertyValue $user.userPrincipalName
        $obj | Add-Member -NotePropertyName accountEnabled -NotePropertyValue $user.accountEnabled
        $obj | Add-Member -NotePropertyName userType -NotePropertyValue $user.userType
        $obj | Add-Member -NotePropertyName state -NotePropertyValue $state
        $obj | Add-Member -NotePropertyName IsAadLicensed -NotePropertyValue ([bool]$hasP1OrP2)    
        $obj | Add-Member -NotePropertyName daysSinceSignIn -NotePropertyValue $daysSinceSignIn
        $obj | Add-Member -NotePropertyName lastSuccessfulSignIn -NotePropertyValue $user.signInActivity.lastSuccessfulSignInDateTime # last successful sign-in
        $obj | Add-Member -NotePropertyName lastInteractiveSignIn -NotePropertyValue $user.signInActivity.lastSignInDateTime # last interactive (success or failure)
        $obj | Add-Member -NotePropertyName lastNonInteractiveSignIn -NotePropertyValue $user.signInActivity.lastNonInteractiveSignInDateTime # last non-interactive (success or failure)
        $obj | Add-Member -NotePropertyName createdDateTime -NotePropertyValue $user.createdDateTime
        if ( $UserType -eq "Member" ) { 
            $obj | Add-Member -NotePropertyName onPremisesSyncEnabled -NotePropertyValue ([bool]$user.onPremisesSyncEnabled) 
            $obj | Add-Member -NotePropertyName manager -NotePropertyValue $user.manager.userPrincipalName
            $obj | Add-Member -NotePropertyName department -NotePropertyValue $user.department
            $obj | Add-Member -NotePropertyName jobTitle -NotePropertyValue $user.jobTitle
            $obj | Add-Member -NotePropertyName companyName -NotePropertyValue $user.companyName
            $obj | Add-Member -NotePropertyName country -NotePropertyValue $user.country
        }
        else {
            $obj | Add-Member -NotePropertyName externalUserState -NotePropertyValue $user.externalUserState
            $obj | Add-Member -NotePropertyName externalUserStateChangeDateTime -NotePropertyValue $user.externalUserStateChangeDateTime
            $obj | Add-Member -NotePropertyName guestDomain -NotePropertyValue $guestDomain
            $obj | Add-Member -NotePropertyName sponsors -NotePropertyValue $sponsors 
        }
        $obj
    }

    Write-GtVerbose "Processed $($report.Count) users"

    # output
    if ($outputType -eq "html") { $report | Export-GtHtmlReport -ReportTitle "User Report ($UserType)" -TitleProperty "displayName" -Path ".\PSGraphToolbox_UserReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $report }
}
