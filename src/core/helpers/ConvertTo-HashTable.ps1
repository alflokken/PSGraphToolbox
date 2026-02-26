function ConvertTo-HashTable {
    <#
    .SYNOPSIS
    Convert array of objects to hashtable keyed by a property.

    .DESCRIPTION
    Faster alternative to Group-Object -AsHashTable (~50x faster for large datasets).
    Creates a hashtable where each key is the value of the specified property.

    .PARAMETER inputObject
    Array of objects to convert. Accepts pipeline input.

    .PARAMETER keyProperty
    Property name to use as hashtable key. Defaults to "id".

    .OUTPUTS
    Hashtable with keyProperty values as keys and full objects as values.

    .EXAMPLE
    $users | ConvertTo-HashTable -keyProperty "id"
    Creates hashtable where $ht["user-guid"] returns the user object.

    .EXAMPLE
    $apps | ConvertTo-HashTable -keyProperty "appId"
    Creates hashtable keyed by appId.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-HashTable.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$inputObject,
        [Parameter(Mandatory = $false)]
        [string]$keyProperty = "id"
    )
    begin {
        $hashTable = @{}
        $keyPropertyVerified = $false
    }
    process {
        # Process each pipeline input object
        foreach ($item in $inputObject) {
            # Verify key property exists on first item
            if (-not $keyPropertyVerified) {
                if (-not $item.PSObject.Properties.Name -contains $keyProperty) { throw "Key property '$keyProperty' does not exist on input objects." }
                $keyPropertyVerified = $true
            }
            $hashTable[$item.$keyProperty] = $item
        }
    }
    end { return $hashTable }
}