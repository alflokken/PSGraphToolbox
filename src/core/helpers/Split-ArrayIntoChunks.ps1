function Split-ArrayIntoChunks {
    <#
    .SYNOPSIS
    Split an array into smaller chunks.

    .DESCRIPTION
    Divides an array into smaller arrays of specified size. 
    Used for batch processing (e.g., Graph API batch limit of 20).

    .PARAMETER Enumerable
    The array to split.

    .PARAMETER ChunkSize
    Maximum items per chunk. Defaults to 20.

    .OUTPUTS
    Array of arrays, each containing up to ChunkSize items.

    .EXAMPLE
    Split-ArrayIntoChunks -Enumerable $users -ChunkSize 20
    Splits user array into batches of 20.

    .EXAMPLE
    $items | chunk -ChunkSize 100
    Uses alias to split items into batches of 100.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Split-ArrayIntoChunks.md
    #>
    [Alias('chunk')]
    param(
        [array]$Enumerable,
        [int]$ChunkSize = 20
    )
    $arr = @()
    for ($a = 0; $a -lt $Enumerable.count; $a += $ChunkSize) {
        $endIndex = $a + $ChunkSize - 1
        if ($endIndex -gt ($Enumerable.count - 1)) {
            $endIndex = $Enumerable.count - 1
        }
        $arr += , $Enumerable[$a..$endIndex]
    }
    return ,$arr  # force array even if single chunk
}