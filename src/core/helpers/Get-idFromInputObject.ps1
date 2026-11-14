function Get-IdFromInputObject {
    <#
    .SYNOPSIS
    Extract identifier from flexible input types.

    .DESCRIPTION
    Normalizes various input types to an ID and type. Accepts strings (GUID or UPN),
    or objects with 'id' or 'userPrincipalName' properties (id is used when both exist).

    The value is classified as 'guid', 'upn' (see isValidUserPrincipalName) or, with -AllowRawString, 'string'.
    Throws for null/empty input, objects without id/userPrincipalName, and values that are neither a GUID nor
    a recognized UPN (e.g. guest #EXT# UPNs or display names) unless -AllowRawString is used.

    .PARAMETER InputObject
    String (GUID/UPN) or object with id/userPrincipalName property. Accepts pipeline input.

    .PARAMETER objectIdOnly
    Require the result to be a valid GUID. Throws if the value is a UPN or any other string.

    .PARAMETER AllowRawString
    Allow non-GUID, non-UPN strings (e.g., displayName). Returns type as "string".

    .OUTPUTS
    PSObject with 'id' (the extracted identifier) and 'type' (guid, upn, or string).

    .EXAMPLE
    Get-IdFromInputObject "user@zavainc.com"
    Returns an object with id 'user@zavainc.com' and type 'upn'.

    .EXAMPLE
    $user | Get-IdFromInputObject -objectIdOnly
    Returns the object ID of the piped user; throws if it is not a valid GUID.

    .EXAMPLE
    Get-IdFromInputObject "Sales Team" -AllowRawString
    Returns an object with id 'Sales Team' and type 'string'.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Get-idFromInputObject.md
    #>
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