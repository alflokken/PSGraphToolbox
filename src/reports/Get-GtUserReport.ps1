function Get-GtUserReport {
    <#
    .SYNOPSIS
    Get a flat report of users or guests with sign-in activity.

    .DESCRIPTION
    Retrieves users or guests from Entra ID with key governance data:
    - Account status (enabled/disabled)
    - Sign-in activity (last sign-in, last non-interactive sign-in)
    - Sync status (cloud-only vs hybrid)
    - inactive account detection based on configurable threshold

    Requires scopes: User.Read.All, AuditLog.Read.All (for signInActivity).

    .PARAMETER UserType
    Filter by user type: Member, Guest, or All. Defaults to Member.

    .PARAMETER MonthsInactive
    Number of months without successful sign-in to flag as inactive. Defaults to 6.

    .PARAMETER outputType
    Output format: PSObject or html. Defaults to html.

    .OUTPUTS
    Array of user report objects (PSObject mode) or HTML report file path (html mode).
    Each object includes: displayName, userPrincipalName, accountEnabled, userType, state (active/inactive/disabled/never signed in), signInActivity, and manager info.

    .EXAMPLE
    Get-GtUserReport
    Returns all member users as HTML report.

    .EXAMPLE
    Get-GtUserReport -UserType Guest -MonthsInactive 12
    Returns guest users, flagging those inactive for 12+ months as inactive.

    .EXAMPLE
    Get-GtUserReport -UserType All -outputType PSObject
    Returns all users as PSObject for further processing.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Get-GtUserReport.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Member", "Guest", "All")]
        [string]$UserType = "Member",

        [Parameter()]
        [int]$MonthsInactive = 6,

        [Parameter()]
        [ValidateSet("PSObject", "html")]
        [string]$outputType = "html"
    )

    # build query params
    $userParams = @{
        resourcePath = "users"
        apiVersion   = "beta"
        select       = "id,userPrincipalName,displayName,accountEnabled,userType,createdDateTime,signInActivity,onPremisesSyncEnabled,onPremisesLastSyncDateTime,department,companyName,jobTitle,country,city"
        expand       = "manager(`$select=userPrincipalName)"
    }

    # filter by userType
    if ($UserType -ne "All") { $userParams['filter'] = "userType eq '$UserType'" }

    Write-Verbose "Retrieving $UserType users..."
    $users = Invoke-GtGraphRequest @userParams

    # calculate inactive threshold
    $inactiveDate = (Get-Date).AddMonths(-$MonthsInactive)

    # build flat report
    $report = foreach ($user in $users) {
        
        # determine state based on lastSuccessfulSignInDateTime (most reliable)
        $lastSuccessful = $user.signInActivity.lastSuccessfulSignInDateTime
        $state = "active"
        if (-not $user.accountEnabled) { $state = "disabled" }
        elseif (-not $lastSuccessful) { $state = "never signed in" }
        elseif ((Get-Date $lastSuccessful) -lt $inactiveDate) { $state = "inactive" }

        # build flat object
        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -NotePropertyName displayName -NotePropertyValue $user.displayName
        $obj | Add-Member -NotePropertyName userPrincipalName -NotePropertyValue $user.userPrincipalName
        $obj | Add-Member -NotePropertyName accountEnabled -NotePropertyValue $user.accountEnabled
        $obj | Add-Member -NotePropertyName userType -NotePropertyValue $user.userType
        $obj | Add-Member -NotePropertyName state -NotePropertyValue $state
        $obj | Add-Member -NotePropertyName lastSuccessfulSignIn -NotePropertyValue $user.signInActivity.lastSuccessfulSignInDateTime # last successful sign-in
        $obj | Add-Member -NotePropertyName lastInteractiveSignIn -NotePropertyValue $user.signInActivity.lastSignInDateTime # last interactive (success or failure)
        $obj | Add-Member -NotePropertyName lastNonInteractiveSignIn -NotePropertyValue $user.signInActivity.lastNonInteractiveSignInDateTime # last non-interactive (success or failure)
        $obj | Add-Member -NotePropertyName createdDateTime -NotePropertyValue $user.createdDateTime
        $obj | Add-Member -NotePropertyName isHybrid -NotePropertyValue ([bool]$user.onPremisesSyncEnabled)
        $obj | Add-Member -NotePropertyName department -NotePropertyValue $user.department
        $obj | Add-Member -NotePropertyName manager -NotePropertyValue $user.manager.userPrincipalName
        $obj | Add-Member -NotePropertyName jobTitle -NotePropertyValue $user.jobTitle
        $obj | Add-Member -NotePropertyName companyName -NotePropertyValue $user.companyName
        $obj | Add-Member -NotePropertyName country -NotePropertyValue $user.country
        $obj
    }

    Write-Verbose "Processed $($report.Count) users"

    # output
    if ($outputType -eq "html") { $report | Export-GtHtmlReport -ReportTitle "User Report ($UserType)" -TitleProperty "displayName" -Path ".\PSGraphToolbox_UserReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html" }
    else { return $report }
}
