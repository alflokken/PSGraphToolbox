function ConvertTo-GtLocalDateTime {
    <#
    .SYNOPSIS
    Recursively convert all dateTime values in an object graph from UTC to local time.

    .DESCRIPTION
    Walks an object, hashtable/dictionary, or array and converts every [datetime] value it
    finds - whether a property value, dictionary entry, or collection element - from UTC to
    local time, in place. Recurses into nested objects, dictionaries and arrays at any depth.
    Compatible with Windows PowerShell 5.1 and Constrained Language Mode.

    Only [datetime] values are modified. Strings, numbers, booleans, GUIDs and the overall
    object structure are preserved unchanged. Conversion is idempotent (a local-time value
    passed back in is returned unchanged), so it is safe to call more than once.

    A dateTime without a time zone (Kind 'Unspecified') is assumed to be UTC. This matches Microsoft Graph, which
    returns UTC; it would shift values from other sources that are already local (e.g. [datetime]'2024-01-15 12:00').

    Used internally by Invoke-GtGraphRequest, Invoke-GtGraphBatchRequest and other functions
    that call Invoke-MgGraphRequest directly, to centralize local-time conversion of Microsoft
    Graph dateTime values, so consuming functions don't each repeat it.

    .PARAMETER InputObject
    The object, hashtable, array, or value to process. Accepts pipeline input.

    .OUTPUTS
    The same object reference with dateTime values converted to local time.
    For a [datetime] input, the converted value is returned (dateTime values are immutable).

    .EXAMPLE
    $user = Invoke-MgGraphRequest -Uri "v1.0/users/$id" -OutputType PSObject
    ConvertTo-GtLocalDateTime -InputObject $user
    Converts all dateTime properties (including nested ones) on the user object to local time.

    .EXAMPLE
    $result = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body
    ConvertTo-GtLocalDateTime -InputObject $result
    Converts dateTime values in a hashtable response (including nested hashtables) to local time.

    .EXAMPLE
    $users | ConvertTo-GtLocalDateTime
    Converts dateTime values for each object piped in.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/ConvertTo-GtLocalDateTime.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject
    )
    process {

        # convert dateTime values
        if ( $InputObject -is [datetime] ) {
            $converted = $InputObject.ToLocalTime()
            Write-Debug "ConvertTo-GtLocalDateTime: dateTime $($InputObject.ToString('o')) -> $($converted.ToString('o'))"
            return $converted
        }

        # nothing to convert for strings and other value types
        if ( $null -eq $InputObject -or $InputObject -is [string] -or $InputObject -is [System.ValueType] ) { return $InputObject }

        # hashtables/dictionaries: PSObject.Properties is Keys/Values/Count
        if ( $InputObject -is [System.Collections.IDictionary] ) {
            # defensive copy (avoid modifying collection while iterating)
            foreach ( $key in @($InputObject.Keys) ) {
                $value = $InputObject[$key]
                if ( $value -is [datetime] ) {
                    $local = $value.ToLocalTime()
                    Write-Debug "ConvertTo-GtLocalDateTime: [$key] $($value.ToString('o')) -> $($local.ToString('o'))"
                    $InputObject[$key] = $local
                }
                # recurse into nested objects
                elseif ( $null -ne $value -and $value -isnot [string] -and $value -isnot [System.ValueType] ) {
                    $null = ConvertTo-GtLocalDateTime -InputObject $value
                }
            }
            return $InputObject
        }

        # arrays(collections)
        if ( $InputObject -is [System.Collections.IList] ) {
            for ( $i = 0; $i -lt $InputObject.Count; $i++ ) {
                $element = $InputObject[$i]
                if ( $element -is [datetime] ) {
                    $local = $element.ToLocalTime()
                    Write-Debug "ConvertTo-GtLocalDateTime: [$i] $($element.ToString('o')) -> $($local.ToString('o'))"
                    $InputObject[$i] = $local
                }
                # recurse into nested objects
                elseif ( $null -ne $element -and $element -isnot [string] -and $element -isnot [System.ValueType] ) {
                    $null = ConvertTo-GtLocalDateTime -InputObject $element
                }
            }
            return $InputObject
        }

        # objects: convert dateTime properties in place, recurse into nested objects/arrays
        foreach ( $property in $InputObject.PSObject.Properties ) {
            $value = $property.Value
            if ( $value -is [datetime] ) {
                $local = $value.ToLocalTime()
                Write-Debug "ConvertTo-GtLocalDateTime: .$($property.Name) $($value.ToString('o')) -> $($local.ToString('o'))"
                # set via the object
                $InputObject.($property.Name) = $local
            }
            # recurse into nested objects
            elseif ( $null -ne $value -and $value -isnot [string] -and $value -isnot [System.ValueType] ) {
                $null = ConvertTo-GtLocalDateTime -InputObject $value
            }
        }
        return $InputObject
    }
}
