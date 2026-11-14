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

    .EXAMPLE
    Get-GtDeltaStateFromJsonFile -Path "C:\state\users-delta.json"
    Returns the stored delta state, or $null on the first run.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Get-GtDeltaStateFromJsonFile.md
    #>
    param([string]$Path)
    # Retrieve delta state from JSON file. Returns $null if file doesn't exist.
    if ( Test-Path $Path ) { return Get-Content $Path -raw -Encoding UTF8 | ConvertFrom-Json }
    return $null
}

function Set-GtDeltaStateToJsonFile {
    <#
    .SYNOPSIS
    Save delta state to a JSON file.

    .DESCRIPTION
    Writes delta query state to a JSON file (UTF-8, compressed, depth 10), overwriting any existing file.
    Used by Sync-GtGraphResourceDelta to persist state between runs.

    .PARAMETER Path
    File path where the delta state will be saved.

    .PARAMETER State
    PSObject containing the delta state to save.

    .EXAMPLE
    Set-GtDeltaStateToJsonFile -Path "C:\state\users-delta.json" -State $state
    Saves the delta state to the file, overwriting any existing content.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Set-GtDeltaStateToJsonFile.md
    #>
    param([string]$Path, [object]$state)
    # Write delta state to JSON file.
    $state | ConvertTo-Json -Depth 10 -Compress | Out-File $Path -Force -Encoding utf8
}

function Test-GtDeltaStateJsonFile {
    <#
    .SYNOPSIS
    Check if a delta state JSON file exists.

    .DESCRIPTION
    Tests whether a delta state file exists at the specified path.
    Throws if the parent directory does not exist, or if the path has no directory part (e.g. 'state.json'; use '.\state.json').
    Used by Sync-GtGraphResourceDelta to validate the storage path before syncing.

    .PARAMETER Path
    File path to check.

    .OUTPUTS
    Boolean: $true if file exists, $false otherwise.

    .EXAMPLE
    Test-GtDeltaStateJsonFile -Path "C:\state\users-delta.json"
    Returns $true if the state file exists. Throws if the parent directory does not exist.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/storageProviders/Test-GtDeltaStateJsonFile.md
    #>
    param([string]$Path)
    # Check if delta state file exists.
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