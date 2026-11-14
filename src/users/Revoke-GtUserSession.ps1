function Revoke-GtUserSession {
    <#
    .SYNOPSIS
    Revoke all refresh tokens for a user.

    .DESCRIPTION
    Invalidates all refresh tokens issued to applications for a user.
    Also invalidates session cookies in the user's browser. Revocation can take a few minutes,
    and does not apply to external (guest) users, who sign in through their home tenant.
    Unless -WhatIf is used or -Confirm is $false, you are prompted to confirm (Y/N).

    Requires scopes: User.RevokeSessions.All (least privileged), or User.ReadWrite.All / Directory.ReadWrite.All.

    .PARAMETER InputObject
    User object, UPN, or object ID. Accepts pipeline input.

    .PARAMETER WhatIf
    Preview the action without making changes.

    .PARAMETER Confirm
    Prompt for confirmation. Defaults to true. Set to $false to skip the prompt.

    .OUTPUTS
    PSObject with userId, success (value returned by Graph) and timestamp. Nothing is returned with -WhatIf or when cancelled.

    .EXAMPLE
    Revoke-GtUserSession -inputObject "user@zavainc.com"
    Revokes all sessions for the user after confirmation.

    .EXAMPLE
    "user@zavainc.com" | Revoke-GtUserSession -WhatIf
    Shows which user's sessions would be revoked, without making changes.

    .EXAMPLE
    Revoke-GtUserSession -inputObject "user@zavainc.com" -Confirm $false
    Revokes all sessions without prompting.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/Revoke-GtUserSession.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,

        [Parameter()]
        [switch]$WhatIf,

        [Parameter()]
        [bool]$Confirm = $true
    )
    process {
        $id = Get-IdFromInputObject -inputObject $InputObject | Select-Object -ExpandProperty id

        if ( $Confirm -and -not $WhatIf ) {
            $confirmation = Read-Host "Revoke all sessions for user '$id'? (Y/N)"
            if ( $confirmation -ne "y" ) { Write-Host "Operation cancelled." -ForegroundColor Yellow; return }
        }
        if ( $WhatIf ) { Write-Host "WhatIf: Would revoke all sessions for user '$id'" -ForegroundColor Yellow; return }

        try { $response = Invoke-MgGraphRequest -Method POST -Uri "v1.0/users/$id/revokeSignInSessions" -OutputType PSObject }
        catch { throw $_ }

        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -NotePropertyName userId -NotePropertyValue $id
        $obj | Add-Member -NotePropertyName success -NotePropertyValue $response.value
        $obj | Add-Member -NotePropertyName timestamp -NotePropertyValue (Get-Date)
        return $obj
    }
}