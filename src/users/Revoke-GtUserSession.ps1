function Revoke-GtUserSession {
    <#
    .SYNOPSIS
    Revoke all refresh tokens for a user.

    .DESCRIPTION
    Invalidates all refresh tokens issued to applications for a user.
    Also invalidates session cookies in the user's browser.
    Requires User.ReadWrite.All or Directory.ReadWrite.All.

    .PARAMETER inputObject
    User object, UPN, or object ID.

    .EXAMPLE
    Revoke-GtUserSession -inputObject "user@zavainc.com"

    .EXAMPLE
    "user@zavainc.com" | Revoke-GtUserSession

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
        $id = idFromInputObject -inputObject $InputObject | Select-Object -ExpandProperty id

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