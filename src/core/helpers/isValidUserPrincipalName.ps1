function isValidUserPrincipalName {
    <#
    .SYNOPSIS
    Validate if a string is a properly formatted UserPrincipalName (UPN).

    .DESCRIPTION
    Tests whether a string matches a basic email/UPN format (user@domain.com).
    The local part may contain letters, digits, '.', '_' and '-'; the domain must end in a 2+ letter TLD.
    Valid Entra UPNs containing other characters (e.g. guest UPNs with #EXT#, or ' ! ^ ~) return $false.
    Pipeline-enabled filter function for validating user principal names.

    .PARAMETER userPrincipalName
    The string to validate as a UPN.

    .OUTPUTS
    Boolean: $true if valid UPN format, $false otherwise.

    .EXAMPLE
    "user@zavainc.com" | isValidUserPrincipalName
    Returns: $true

    .EXAMPLE
    isValidUserPrincipalName "invalid-upn"
    Returns: $false

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/isValidUserPrincipalName.md
    #>
    param (
        [Parameter(ValueFromPipeline)]
        [string]$userPrincipalName
    )
    begin { 
        [regex]$upnRegex = "^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    }
    process { return $userPrincipalName -match $upnRegex }
}