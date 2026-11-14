function ConvertTo-HashTable {
    <#
    .SYNOPSIS
    Convert array of objects to hashtable keyed by a property.

    .DESCRIPTION
    Creates a 1:1 lookup hashtable where each key is the value of the specified property and the value is a single object.
    Use only when keyProperty is unique (e.g. id, appId).

    NOT a drop-in replacement for Group-Object -AsHashTable: duplicate keys are silently overwritten (last object wins).
    For 1:many relations (e.g. role assignments by principalId), use Group-Object -Property <name> -AsHashTable -AsString.
    Much faster than Group-Object -AsHashTable (~50x for large datasets) when keys are unique.

    .PARAMETER inputObject
    Array of objects (or hashtables) to convert. Accepts pipeline input. Null or empty input returns an empty hashtable; items that are themselves $null are skipped.

    .PARAMETER keyProperty
    Property name to use as hashtable key. Defaults to "id".

    .OUTPUTS
    Hashtable with keyProperty values as keys and full objects as values.
    Throws if a non-null item has a missing or null keyProperty value. Duplicate keys: the last object wins.

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
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$inputObject,
        [Parameter(Mandatory = $false)]
        [string]$keyProperty = "id"
    )
    begin { $hashTable = @{} }
    process {
        foreach ($item in $inputObject) {
            if ($null -eq $item) { continue }
            $key = $item.$keyProperty
            if ($null -eq $key) { throw "Key property '$keyProperty' is missing or null on an input object." }
            $hashTable[$key] = $item
        }
    }
    end { return $hashTable }
}