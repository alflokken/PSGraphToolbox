function Get-StrictMode {
    <#
    .SYNOPSIS
        Detect the currently active StrictMode version.

    .DESCRIPTION
        Returns the StrictMode version (1, 2, 3) or 0 if StrictMode is off.
        Useful for conditional logic based on strictness level.
        Credit: Theo@StackOverflow (https://stackoverflow.com/a/63098649)

    .OUTPUTS
        Int: 0 (off), 1, 2, or 3.

    .EXAMPLE
        Get-GtStrictMode
        Returns current StrictMode level.
    #>
    try { $xyz = @(1); $null = ($null -eq $xyz[2])}
    catch { return 3 }
    try { "Not-a-Date".Year }
    catch { return 2 }
    try { $null = ($undefined -gt 1) }
    catch { return 1 }
    return 0
}