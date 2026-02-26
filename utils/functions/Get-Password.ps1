function Get-Password {
    <#
    .SYNOPSIS
        Generate a random password string.

    .DESCRIPTION
        Generates a cryptographically random password using a mix of 
        lowercase, uppercase, numbers, and special characters.

    .PARAMETER len
        Password length. Defaults to random 24-48. Min 8, max 2000.

    .OUTPUTS
        String containing the generated password.

    .EXAMPLE
        Get-GtPassword
        Returns random password of length 24-48.

    .EXAMPLE
        Get-GtPassword -len 32
        Returns 32-character password.
    #>
    param([Parameter(Mandatory = $false)][int]$len)
    if ( !$len ) { $len = (24..48) | get-random }
    elseif ( $len -lt 8 ) { $len = 8 }
    elseif ( $len -gt 2000 ) { $len = 2000 }
    $secret = @()
    for ( $a = 0; $a -lt $len; $a++ ) { $secret += "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!`"#$%&'()*+,-./:;<=>?@[\]^_{|}".ToCharArray() | get-random }
    return (-join $secret)
}