function isValidGuid {
    <#
    .SYNOPSIS
    Validate if a string is a properly formatted GUID.

    .DESCRIPTION
    Tests whether a string matches the standard GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).
    Pipeline-enabled filter function for validating object IDs.

    .PARAMETER guid
    The string to validate as a GUID.

    .OUTPUTS
    Boolean: $true if valid GUID format, $false otherwise.

    .EXAMPLE
    "d1d10c1f-4f2e-4f2e-4f2e-4f2e4f2e4f2e" | isValidGuid
    Returns: $true

    .EXAMPLE
    isValidGuid "not-a-guid"
    Returns: $false

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/isValidGuid.md
    #>
    param (
        [Parameter(ValueFromPipeline)]
        [string]$guid
    )
    begin { [regex]$guidRegex = "(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$" } # matches standard GUID format 
    process {  return $guid -match $guidRegex }
}