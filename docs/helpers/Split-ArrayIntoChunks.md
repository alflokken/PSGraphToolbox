---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Split-ArrayIntoChunks.md
schema: 2.0.0
---

# Split-ArrayIntoChunks

## SYNOPSIS
Split an array into smaller chunks.

## SYNTAX

```
Split-ArrayIntoChunks [[-Enumerable] <Array>] [[-ChunkSize] <Int32>]
```

## DESCRIPTION
Divides an array into smaller arrays of specified size. 
Used for batch processing (e.g., Graph API batch limit of 20).

## EXAMPLES

### EXAMPLE 1
```
Split-ArrayIntoChunks -Enumerable $users -ChunkSize 20
```

Splits user array into batches of 20.

### EXAMPLE 2
```
$items | chunk -ChunkSize 100
```

Uses alias to split items into batches of 100.

## PARAMETERS

### -Enumerable
The array to split.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChunkSize
Maximum items per chunk.
Defaults to 20.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 20
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### Array of arrays, each containing up to ChunkSize items.
## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Split-ArrayIntoChunks.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/helpers/Split-ArrayIntoChunks.md)

