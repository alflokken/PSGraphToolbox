function Get-idFromInputObject {
    <#
    .SYNOPSIS
    Extract identifier from flexible input types.

    .DESCRIPTION
    Normalizes various input types to an ID and type. Accepts strings (GUID or UPN),
    or objects with 'id' or 'userPrincipalName' properties.

    .PARAMETER InputObject
    String (GUID/UPN) or object with id/userPrincipalName property.

    .PARAMETER objectIdOnly
    Require the result to be a valid GUID. Throws if input is UPN or string.

    .PARAMETER AllowRawString
    Allow non-GUID, non-UPN strings (e.g., displayName). Returns type as "string".

    .OUTPUTS
    PSObject with 'id' (the extracted identifier) and 'type' (guid, upn, or string).

    .EXAMPLE
    Get-idFromInputObject "user@zavainc.com"
    # Returns: @{ id = "user@zavainc.com"; type = "upn" }

    .EXAMPLE
    $user | Get-idFromInputObject -objectIdOnly
    # Extracts object ID, throws if not a valid GUID.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Get-idFromInputObject.md
    #>
    [Alias('idFromInputObject')]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [Object]$InputObject,
        [switch]$objectIdOnly,
        [switch]$AllowRawString
    )
    process {
        if ( -not $InputObject ) { throw "input object is null or empty." }

        $responseObject = new-object PSObject -Property @{
            id = $null
            type = $null
        }

        # populate response id
        if ( $InputObject -is [string] ) { $responseObject.id = $InputObject }
        elseif ( $InputObject.PSObject.Properties['id'] ) { $responseObject.id = $InputObject.id }
        elseif ($InputObject.PSObject.Properties['userPrincipalName']) { $responseObject.id = $InputObject.userPrincipalName }
        else { throw "Unsupported input. Must be string or object with identifier." }

        # determine response type (upn/guid/string)
        if ( $responseObject.id | isValidGuid ) { $responseObject.type = "guid" }
        elseif ( $objectIdOnly ) { throw "'$($responseObject.id)' is not a valid objectId." }
        elseif ( $responseObject.id | isValidUserPrincipalName ) { $responseObject.type = "upn" }
        elseif ( $AllowRawString ) { $responseObject.type = "string" }
        else { throw "'$($responseObject.id)' is not a valid GUID or UserPrincipalName." }
        return $responseObject
    }
}