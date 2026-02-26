# Storage providers for Sync-GtGraphResourceDelta
# Used for persisting delta query state between runs

# JSON File Provider - stores delta state in a local JSON file
function Get-GtDeltaStateFromJsonFile {
    <#
    .SYNOPSIS
    Retrieve delta state from a JSON file.

    .DESCRIPTION
    Reads delta query state from a JSON file. Returns $null if the file doesn't exist.
    Used by Sync-GtGraphResourceDelta to persist state between runs.

    .PARAMETER Path
    File path where the delta state is stored.

    .OUTPUTS
    PSObject containing the delta state, or $null if file doesn't exist.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Get-GtDeltaStateFromJsonFile.md
    #>
    # Retrieve delta state from JSON file. Returns $null if file doesn't exist.
    param([string]$Path)
    if ( Test-Path $Path ) { return Get-Content $Path -raw -Encoding UTF8 | ConvertFrom-Json }
    return $null
}

function Set-GtDeltaStateToJsonFile {
    <#
    .SYNOPSIS
    Save delta state to a JSON file.

    .DESCRIPTION
    Writes delta query state to a JSON file with UTF-8 encoding.
    Used by Sync-GtGraphResourceDelta to persist state between runs.

    .PARAMETER Path
    File path where the delta state will be saved.

    .PARAMETER State
    PSObject containing the delta state to save.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Set-GtDeltaStateToJsonFile.md
    #>
    # Write delta state to JSON file.
    param([string]$Path, [object]$state)
    $state | ConvertTo-Json -Depth 10 -Compress | Out-File $Path -Force -Encoding utf8
}

function Test-GtDeltaStateJsonFile {
    <#
    .SYNOPSIS
    Check if a delta state JSON file exists.

    .DESCRIPTION
    Tests whether a delta state file exists at the specified path.
    Used by Sync-GtGraphResourceDelta to validate state file presence.

    .PARAMETER Path
    File path to check.

    .OUTPUTS
    Boolean: $true if file exists, $false otherwise.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Test-GtDeltaStateJsonFile.md
    #>
    # Check if delta state file exists.
    param([string]$Path)
    $parent = Split-Path $Path -Parent
    if ( -not (Test-Path $parent) ) { throw "Directory $parent does not exist." }
    return Test-Path $Path
}
<# SQL Provider (future) todo
#function Get-GtDeltaStateFromSql {
    param([string]$Path) # Could be connection string
    # Invoke-SqlCmd logic here
}
#function Set-GtDeltaStateToSql {
    param([string]$Path, [object]$state)
    # Invoke-SqlCmd logic here
}
#>