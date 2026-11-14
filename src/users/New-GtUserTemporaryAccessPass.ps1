function New-GtUserTemporaryAccessPass {
    <#
    .SYNOPSIS
    Issue a new Temporary Access Pass (TAP) for a user.

    .DESCRIPTION
    Creates a new Temporary Access Pass for a user via MS Graph API.
    Unless -WhatIf is used or -Confirm is $false, you are prompted to confirm (Y/N).
    The tenant's Temporary Access Pass policy must allow the requested lifetime and usage.

    Requires scopes: UserAuthenticationMethod.ReadWrite.All.

    .PARAMETER inputObject
    User object, UPN, or object ID. Accepts pipeline input.

    .PARAMETER LifetimeInMinutes
    TAP validity duration in minutes (10-43200). Defaults to 60.

    .PARAMETER IsUsableOnce
    If specified, the TAP can only be used once. By default the TAP is multi-use.

    .PARAMETER WhatIf
    Preview the action without making changes.

    .PARAMETER Confirm
    Prompt for confirmation. Defaults to true. Set to $false to skip the prompt.

    .OUTPUTS
    PSObject with userId, temporaryAccessPass (the pass in clear text), lifetimeInMinutes, isUsableOnce,
    startDateTime (local time) and methodUsabilityReason. Nothing is returned with -WhatIf or when cancelled.

    .EXAMPLE
    New-GtUserTemporaryAccessPass -inputObject "user@zavainc.com"
    Issues a 60-minute TAP for the user after confirmation.

    .EXAMPLE
    "user@zavainc.com" | New-GtUserTemporaryAccessPass -LifetimeInMinutes 480 -IsUsableOnce
    Issues a single-use 8-hour TAP for the user.

    .EXAMPLE
    New-GtUserTemporaryAccessPass "user@zavainc.com" -Confirm $false
    Issues a TAP without prompting (for automation).

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/users/New-GtUserTemporaryAccessPass.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,

        [Parameter()]
        [ValidateRange(10, 43200)]
        [int]$LifetimeInMinutes = 60,

        [Parameter()]
        [switch]$IsUsableOnce,

        [Parameter()]
        [switch]$WhatIf,

        [Parameter()]
        [bool]$Confirm = $true
    )
    process {
        $id = Get-IdFromInputObject -inputObject $InputObject | Select-Object -ExpandProperty id

        # confirm
        if ( $Confirm -and -not $WhatIf ) {
            $confirmation = Read-Host "Issue TAP for user '$id'? (Y/N)"
            if ($confirmation -ne "Y" -and $confirmation -ne "y") { Write-Host "Operation cancelled." -ForegroundColor Yellow; return }
        }
        if ( $WhatIf ) { Write-Host "WhatIf: Would issue TAP for user '$id' (lifetime: $LifetimeInMinutes min, usableOnce: $IsUsableOnce)" -ForegroundColor Yellow; return }

        $body = @{
            lifetimeInMinutes = $LifetimeInMinutes
            isUsableOnce      = [bool]$IsUsableOnce
        } | ConvertTo-Json

        try { $response = Invoke-MgGraphRequest -Method POST -Uri "v1.0/users/$id/authentication/temporaryAccessPassMethods" -Body $body -ContentType "application/json" -OutputType PSObject }
        catch { throw $_ }

        # convert dateTime values (UTC -> local) in place
        $null = ConvertTo-GtLocalDateTime -InputObject $response

        # return key info
        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -NotePropertyName userId -NotePropertyValue $id
        $obj | Add-Member -NotePropertyName temporaryAccessPass -NotePropertyValue $response.temporaryAccessPass
        $obj | Add-Member -NotePropertyName lifetimeInMinutes -NotePropertyValue $response.lifetimeInMinutes
        $obj | Add-Member -NotePropertyName isUsableOnce -NotePropertyValue $response.isUsableOnce
        $obj | Add-Member -NotePropertyName startDateTime -NotePropertyValue $response.startDateTime
        $obj | Add-Member -NotePropertyName methodUsabilityReason -NotePropertyValue $response.methodUsabilityReason
        return $obj
    }
}