function Disable-GtApplication {
    <#
    .SYNOPSIS
    Disable app registration and service principal.

    .DESCRIPTION
    Looks up the application registration and the service principal by appId and disables them:
    - Application registration (only if it exists in this tenant): sets isDisabled = true (beta endpoint).
      This disables the app globally, in every tenant where it is used.
    - Service principal (if it exists in this tenant): sets accountEnabled = false (this tenant only).
    If neither is found, a warning is written and the input is skipped. Unless -WhatIf is used or -Confirm is $false,
    you are prompted to confirm (Y/N). Status is written to the host; nothing is returned.

    Requires scopes: Application.ReadWrite.All.

    .PARAMETER InputObject
    Object with an appId property (e.g. output from Find-GtServicePrincipal or Find-GtApplication), or an appId (GUID).
    Object IDs and display names are not accepted. Accepts pipeline input.

    .PARAMETER WhatIf
    Preview changes without making them.

    .PARAMETER Confirm
    Prompt for confirmation. Defaults to true. Set to $false to skip the prompt.

    .OUTPUTS
    None. Results are written to the host.

    .EXAMPLE
    Find-GtServicePrincipal "MigrationWiz" | Disable-GtApplication -WhatIf
    Previews which app registration and service principal would be disabled.

    .EXAMPLE
    Disable-GtApplication -InputObject "00000000-0000-0000-0000-000000000000" -Confirm $false
    Disables the app registration and service principal for the appId without prompting.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/applications/Disable-GtApplication.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,
        [switch]$WhatIf,
        [bool]$Confirm = $true
    )
    process {
        $appId = if ( $InputObject.appId ) { $InputObject.appId } else { $InputObject }
        $appId = Get-IdFromInputObject -inputObject $appId -objectIdOnly | Select-Object -ExpandProperty id

        $registration = Invoke-GtGraphRequest -resourcePath "applications" -filter "appId eq '$appId'" -select "id,displayName" -Verbose:$false
        $spn = Invoke-GtGraphRequest -resourcePath "servicePrincipals" -filter "appId eq '$appId'" -select "id,displayName" -Verbose:$false
        if ( -not $registration -and -not $spn ) { Write-Warning "No application or service principal found for appId '$appId'. Skipping."; return }

        $displayName = @($registration, $spn | Where-Object { $_ })[0].displayName
        $scope = if ( $registration ) { "GLOBAL + tenant-local" } else { "tenant-local only" }

        # confirm (constrained language mode does not support ShouldProcess)
        if ( $Confirm -and -not $WhatIf ) {
            $confirmation = Read-Host "Are you sure you want to disable app '$displayName' [$appId] ($scope)? (Y/N)"
            if ( $confirmation -ne "Y" -and $confirmation -ne "y" ) {
                Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                return
            }
        }

        if ( $WhatIf ) { Write-Host "WhatIf: Would disable app '$displayName' [$appId] ($scope)." -ForegroundColor Yellow; return }

        if ( $registration ) {
            $body = @{ isDisabled = $true } | ConvertTo-Json
            Invoke-MgGraphRequest -Method PATCH -Uri "/beta/applications/$($registration.id)" -Body $body -ContentType "application/json" -ErrorAction Stop
            Write-Host "Disabled application '$displayName' [$appId]" -ForegroundColor Red
        }

        if ( $spn ) {
            $body = @{ accountEnabled = $false } | ConvertTo-Json
            Invoke-MgGraphRequest -Method PATCH -Uri "/beta/servicePrincipals/$($spn.id)" -Body $body -ContentType "application/json" -ErrorAction Stop
            Write-Host "Disabled service principal '$displayName' [$appId]" -ForegroundColor Red
        }
    }
}