function Sync-GtGraphResourceDelta {
    <#
    .SYNOPSIS
    Synchronize Graph resources using delta queries and persistent state.

    .DESCRIPTION
    Performs incremental synchronization of Microsoft Graph resources using delta queries.
    Tracks changes (additions, updates, removals) between sync operations and maintains
    state using pluggable storage providers.

    First call performs a full sync. Subsequent calls retrieve only changes since last sync.
    Handles delta token expiration (410 Gone) by automatically performing a full resync.

    Requires scopes: Varies by resource path (e.g., User.Read.All for users/delta).

    .PARAMETER ResourcePath
    The Graph API delta resource path (e.g., "users/delta", "groups/delta").

    Append "?deltaToken=latest" to skip initial full sync and only track future changes, be aware
    that this does not support filter parameters.

    .PARAMETER SelectProperties
    Comma-separated list of properties to track. The 'id' property is automatically 
    included if not specified.

    .PARAMETER Filter
    OData $filter expression to apply to the delta query.

    .PARAMETER StorageProvider
    Storage backend for persisting delta state. Currently supports: JsonFile.
    Future options may include Sql, CosmosDb, etc.

    .PARAMETER StoragePath
    Path to the storage file (for JsonFile provider).

    .PARAMETER NoWrite
    Skip writing updated state to storage. Useful for testing or dry-run scenarios.

    .OUTPUTS
    PSObject with:
    - ChangeLog: Array of change records (entityId, change type, description)
    - CurrentState: Updated state object containing all entities and deltaLink
    - ItemCount: Total number of entities in current state

    .EXAMPLE
    Sync-GtGraphResourceDelta -ResourcePath "users/delta" -SelectProperties "id,displayName,accountEnabled" -StorageProvider JsonFile -StoragePath ".\userState.json"
    
    Performs delta sync of users, storing state in JSON file.

    .EXAMPLE
    $result = Sync-GtGraphResourceDelta -ResourcePath "users/delta?deltaToken=latest" -SelectProperties "id,displayName" -StoragePath ".\users.json"
    
    Start tracking from current state (skip initial full sync). Useful when you only care about future changes.

    .EXAMPLE
    $result = Sync-GtGraphResourceDelta -ResourcePath "groups/delta" -SelectProperties "id,displayName,members" -Filter "id eq 'group-guid-here'" -StoragePath ".\members.json"
    $result.ChangeLog | Where-Object { $_.description -match 'members_added' }

    Changelog format: 'members_removed: id1, id2; members_added: id3, id4'

    .NOTES 
    For groups, expanding members have known limitations in Graph delta queries. Initial sync may not return complete member lists due to API behavior. 
    Consider using a hybrid approach (regular group members retrieval followed by delta queries) for reliable results.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/core/Sync-GtGraphResourceDelta.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern("delta")]
        [string]$ResourcePath,

        [Parameter(Mandatory=$false)][string]$SelectProperties,
        [Parameter(Mandatory=$false)][string]$Filter = $null,

        [ValidateSet('JsonFile')]    [string]$StorageProvider = "JsonFile", # future: 'Sql', 'CosmosDb' etc.
        [Parameter(Mandatory=$true)] [string]$StoragePath,
        
        [switch]$NoWrite
    )

    #region nested helper functions
    # helper for verbose output
    function timeStamp { return (Get-Date).ToString("yyyy-MM-dd HH:mm:ss:") }
    # helper to compare two objects and return a description of property changes (used for changelog)
    function Get-ObjectChangeDetails {
        <#
        .SYNOPSIS
            Compares two objects and returns a description of property changes.
        .DESCRIPTION
            Internal helper function for Sync-GtGraphResourceDelta.
            Compares properties between reference and difference objects, returning 
            a string describing what changed. Skips @delta relationships as they are 
            handled separately with detailed change tracking.
        #>
        param(
            [object]$ReferenceObject,
            [object]$DifferenceObject
        )
        $changes = @()
        foreach ( $prop in $DifferenceObject.PSObject.Properties.Name ) {
            # Skip @delta properties - they're handled separately with detailed change tracking
            if ( $prop -match '@delta$' ) { continue }
            
            $oldVal = $ReferenceObject.$prop
            $newVal = $DifferenceObject.$prop
            if ( $newVal -is [string] -or $newVal -is [bool] ) {
                if ( $oldVal -ne $newVal ) { $changes += "$prop changed from '$oldVal' to '$newVal'; " }
            }
            else {
                $oldJson = $oldVal | ConvertTo-Json -Compress
                $newJson = $newVal | ConvertTo-Json -Compress
                if ( $oldJson -ne $newJson ) { $changes += "$prop was updated; " }
            }
        }
        if ( $changes ) { return ($changes -join "") }
        else { return $null }
    }
    #endregion

    #region init
    if ( -not (Get-MgContext) ) { throw "No Microsoft Graph context found. Please connect using Connect-MgGraph." }
    else                        { $tenantId = (Get-MgContext).tenantId }

    # Get storage provider functions
    $getStateFunction = Get-Command "Get-GtDeltaStateFrom$StorageProvider" -ErrorAction Stop
    $setStateFunction = Get-Command "Set-GtDeltaStateTo$StorageProvider" -ErrorAction Stop
    $testStateFunction = Get-Command "Test-GtDeltaState$StorageProvider" -ErrorAction Stop

    # Storage provider validation
    try { & $testStateFunction -Path $StoragePath }
    catch { throw $_ }

    # Sync from now - skip state retrieval
    if ( $ResourcePath -match "deltaToken=latest" ) { 
        Write-Verbose "$(timeStamp) deltaToken=latest detected - will skip historical data and track only future changes"
        if ( $Filter ) { Write-Warning "Filter parameter is not honored by deltaToken=latest. The returned deltaLink will track all resources in the collection." }
        $previousState = $null 
    }
    # Retrieve previous state from storage (if exists)
    else {
        Write-Debug "$(timeStamp) Retrieving previous state from $StoragePath using $StorageProvider provider"
        $previousState = & $getStateFunction -Path $StoragePath
    }

    # Normalize select properties - ensure 'id' is included for entity tracking and lookups
    if ( $SelectProperties ) {
        if ( $SelectProperties -notmatch "\bid\b" ) { $SelectProperties += ",id" }
        $SelectProperties = ($SelectProperties -split "," | ForEach-Object { $_.Trim() } | Sort-Object -Unique) -join ","
    }
    
    # Initialize updated state object. 
    $updatedState = New-Object -TypeName PSObject
    Add-Member -InputObject $updatedState -NotePropertyMembers @{
        value = $null
        dateRetrieved = $null
        deltaLink = $null
        # unique identifier for this query configuration, used for state validation (if params change, state is stale)
        queryId = "$tenantId|$ResourcePath|$Filter|$($SelectProperties -replace ',','-')" -replace "[|]+","|" 
    }

    $changeLog = @()
    #endregion

    #region validate state
    # State is valid only if ALL criteria are met:
    # 1. State object exists (not null/empty)
    # 2. State contains deltaLink from previous sync
    # 3. Current query parameters match stored queryId (if params change, state is stale)
    $stateHasDeltaLink    = $previousState -and $previousState.PSObject.Properties.Name -contains "deltaLink"
    $queryParamsMatch     = $previousState -and $previousState.queryId -eq $updatedState.queryId
    $isValidPreviousState = $stateHasDeltaLink -and $queryParamsMatch
    if ( -not $isValidPreviousState ) {
        if ( $previousState ) {
            Write-Warning "Stored state is invalid or query parameters have changed. Existing state will be overwritten."
            Write-Verbose "$(timeStamp) Stored queryId: $($previousState.queryId)"
            Write-Verbose "$(timeStamp) Current queryId: $($updatedState.queryId)"
        }
        else { Write-Verbose "$(timeStamp) No previous state found: performing full sync" }
    }
    #endregion

    #region delta query
    if ( $isValidPreviousState ) {
        Write-Verbose "$(timeStamp) Performing incremental delta query (last sync: $($previousState.dateRetrieved))"
        try { $deltaQueryResults = Invoke-GtGraphRequest -resourcePath $previousState.deltaLink -pageLimit 9999 -Verbose:$false } #-AdditionalHeaders  @{"Prefer" = "return=minimal"}
        catch {
            # Delta token expiration handling:
            # HTTP 410 Gone: deltaLink explicitly expired (Graph discarded history after 30 days)
            # HTTP 400 'DeltaLink older than': deltaLink is too old (Graph may discard if too many changes occurred, even before 30 days)
            $statusCode = $_.Exception.Response.StatusCode.value__ 
            if ( $statusCode -eq 410 -or ($statusCode -eq 400 -and $_.ErrorDetails.Message -match "DeltaLink older than") ) {
                Write-Warning "Delta token expired, performing full resync."
                $isValidPreviousState = $false
            }
            else { throw $_ }
        }
    }
    #endregion

    #region process changes
    if ( $isValidPreviousState -and $deltaQueryResults.value.Count -eq 0 ) {
        Write-Verbose "$(timeStamp) No changes detected since last sync. Updated deltaLink and dateRetrieved in state."
        $updatedState.value = $previousState.value
        $updatedState.dateRetrieved = $deltaQueryResults.dateRetrieved
        $updatedState.deltaLink = $deltaQueryResults.deltaLink
    }
    elseif ( $isValidPreviousState -and $deltaQueryResults.value.Count -gt 0 ) {
        
        # Build hashtable index for entity lookups
        $entityLookup = ConvertTo-HashTable -InputObject $previousState.value -KeyProperty "id"
        Write-Verbose "$(timeStamp) Processing $($deltaQueryResults.value | measure | select -expand count) changed entities (current entity count: $($entityLookup.Count))"

        foreach ( $changedEntity in $deltaQueryResults.value ) {
        
            Write-Debug "Processing entity: $($changedEntity.id)"
            [string]$changeType        = $null
            [string]$changeDescription = $null 
            [string]$entityName        = $null
            
            $existingEntity = $entityLookup[$changedEntity.id]

            if ( $changedEntity.'@removed' ) {
                $changeType = "REMOVE"
                if ( $existingEntity ) { 
                    
                    # best effort to get displayName for changeLog
                    if ( $existingEntity.PSObject.Properties.Name -contains "userPrincipalName" ) { $entityName = $existingEntity.userPrincipalName }
                    elseif ( $existingEntity.PSObject.Properties.Name -contains "displayName" ) { $entityName = $existingEntity.displayName }
                    
                    $entityLookup.Remove($changedEntity.id)
                    Write-Debug "Removed entity from state" 
                }
                else { Write-Debug "Entity not found in state (possible delta replay scenario)" }
            }
            # merge changes 
            elseif ( $existingEntity ) {

                $changeType = "UPDATE"
                $changeDescription = Get-ObjectChangeDetails -ReferenceObject $existingEntity -DifferenceObject $changedEntity

                # Step 1: Extract and process relationship annotations (e.g., members@delta).
                $nestedDeltaProps = $changedEntity.PSObject.Properties.Name | Where-Object { $_ -match "@delta$" }
                foreach ( $nestedDeltaProp in $nestedDeltaProps ) { 
                    Write-Debug "Processing relationship annotation: $nestedDeltaProp"
                    $propBaseName = $nestedDeltaProp -replace '@delta$'

                    # Step 1a: Build lookup of existing relationship members (check both base name and @delta variant for robustness)
                    $existingRelationshipMembers = $existingEntity.$propBaseName
                    if ( -not $existingRelationshipMembers ) { $existingRelationshipMembers = $existingEntity.$nestedDeltaProp }
                    if ( $existingRelationshipMembers ) { $nestedEntityLookup = ConvertTo-HashTable -InputObject $existingRelationshipMembers -KeyProperty id }
                    else { $nestedEntityLookup = @{} }

                    Write-Debug "Existing relationship members.: $($existingRelationshipMembers | ConvertTo-Json -Depth 5 -Compress)"
                    Write-Debug "Changed relationship members..: $($changedEntity.$nestedDeltaProp | ConvertTo-Json -Depth 5 -Compress)"

                    # Step 1b: Detect added vs removed relationship members
                    $addedIds = @(); $removedIds = @()
                    foreach ( $member in $changedEntity.$nestedDeltaProp ) {
                        Write-Debug "Processing relationship member: $($member.id)"
                        if ( $member.'@removed' ) {
                            $removedIds += $member.id
                            $nestedEntityLookup.Remove($member.id)
                            Write-Debug "Removed $($member.id) from $nestedDeltaProp"
                        }
                        else {
                            $addedIds += $member.id
                            $nestedEntityLookup[$member.id] = $member
                            Write-Debug "Upserted $($member.id) to $nestedDeltaProp"
                        }
                    }
                    
                    # Format nested changes: "members_removed: id1, id2; members_added: id3, id4"
                    if ( $removedIds.Count -gt 0 ) { $changeDescription += "$($propBaseName)_removed: $($removedIds -join ', '); " }
                    if ( $addedIds.Count -gt 0 )   { $changeDescription += "$($propBaseName)_added: $($addedIds -join ', '); " }
                    
                    # Clean up legacy @delta property name from existing entity if present
                    if ( $existingEntity.PSObject.Properties.Name -contains $nestedDeltaProp ) { $existingEntity.PSObject.Properties.Remove($nestedDeltaProp) }

                    # Rename: members@delta → members (merge loop will handle the rest)
                    $changedEntity.PSObject.Properties.Remove($nestedDeltaProp)
                    Add-Member -InputObject $changedEntity -NotePropertyName $propBaseName -NotePropertyValue @($nestedEntityLookup.Values)
                }

                # Step 2: Merge changed properties into existing entity. This preserves properties that didn't change in sparse responses with only deltas.
                foreach ( $prop in $changedEntity.PSObject.Properties.Name ) {
                    if ( $prop -eq '@removed' ) { continue }
                    # Merge: add new properties, update existing ones
                    if ( $existingEntity.PSObject.Properties.Name -contains $prop ) { $existingEntity.$prop = $changedEntity.$prop }
                    else { Add-Member -InputObject $existingEntity -NotePropertyName $prop -NotePropertyValue $changedEntity.$prop }
                }
                $entityLookup[$changedEntity.id] = $existingEntity

                if ( -not $changeDescription ) { $changeDescription = "Entity updated (no tracked property changes detected)" } # underlying properties changed but not tracked
                Write-Debug $changeDescription
            }
            else { 
                $changeType = "ADD"
                $entityLookup.Add($changedEntity.id, $changedEntity)
                Write-Debug "Added new entity to state"
            }

            # best available name for changelog - prefer userPrincipalName or displayName if present
            if ( $changeDescription -match "userPrincipalName" -or $changeType -eq "ADD" ) { $entityName = $changedEntity.userPrincipalName }
            elseif ( $existingEntity.userPrincipalName ) { $entityName = $existingEntity.userPrincipalName }
            elseif ( $changeDescription -match "displayName" -or $changeType -eq "ADD" ) { $entityName = $changedEntity.displayName }
            elseif ( $existingEntity.displayName ) { $entityName = $existingEntity.displayName }
            
            $changeLog += New-Object -TypeName PSObject -Property @{
                change      = $changeType
                entityId    = $changedEntity.id
                entityName  = $entityName
                description = $changeDescription
            }
        }

        # Build final state with unique entities (merging changes into previous state)
        $updatedState.value = @($entityLookup.Values)
        $updatedState.dateRetrieved = $deltaQueryResults.dateRetrieved
        $updatedState.deltaLink = $deltaQueryResults.deltaLink
        
        # Verbose summary of changes: "UPDATE: 52, ADD: 32, REMOVE: 3"
        $changeSummary = ($changeLog | Group-Object change | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', '
        Write-Verbose "$(timeStamp) Incremental sync complete: $changeSummary"
    }
    #endregion
    #region full sync
    else {
        Write-Verbose "$(timeStamp) Performing initial (full) sync: $ResourcePath"
        $queryParams = @{
            resourcePath    = $ResourcePath
            pageLimit       = 9999
            top             = 999
            Debug           = $false
        }
        if ( $SelectProperties ) { $queryParams['select'] = $SelectProperties }
        if ( $Filter )           { $queryParams['filter'] = $Filter }

        # Execute delta query
        try { $deltaQueryResults = Invoke-GtGraphRequest @queryParams -Verbose:$false }
        catch { throw $_ }

        # Filter out any @removed entities from initial sync response
        $deltaQueryResults.value = $deltaQueryResults.value | Where-Object { -not $_.'@removed' }

        # Rename @delta properties to base names (e.g., members@delta → members)
        # Also clean @removed markers and deduplicate by id
        foreach ( $entity in $deltaQueryResults.value ) {
            $entity.PSObject.Properties.Name | Where-Object { $_ -match "@delta$" } | ForEach-Object {
                $baseName = $_ -replace '@delta$'
                $cleanedValue = @($entity.$_ | Where-Object { -not $_.'@removed' } | Sort-Object -Property id -Unique)
                $entity.PSObject.Properties.Remove($_)
                Add-Member -InputObject $entity -NotePropertyName $baseName -NotePropertyValue $cleanedValue
            }
        }

        # Build final state with unique entities (no previous state))
        $updatedState.value = @($deltaQueryResults.value | Sort-Object -Property id -Unique)
        $updatedState.dateRetrieved = $deltaQueryResults.dateRetrieved
        $updatedState.deltaLink = $deltaQueryResults.deltaLink
        Write-Verbose "$(timeStamp) Initial sync complete: $($updatedState.value.Count) items retrieved"
    }
    #endregion

    # write updated state to storage (unless nowrite switch is set)
    if ( $NoWrite ) { Write-Verbose "$(timeStamp) Skipping writing updated delta state to $StoragePath (nowrite switch set)" }
    else { 
        & $setStateFunction -Path $StoragePath -State $updatedState
        Write-Verbose "$(timeStamp) State written to $StoragePath"
    }

    # output result object with change log and current state
    $syncResult = New-Object PSObject
    Add-Member -InputObject $syncResult -NotePropertyMembers @{
        ChangeLog    = ($changeLog | Select-Object entityId,entityName,change,description)
        CurrentState = $updatedState
        ItemCount    = $updatedState.value.Count
    }
    return $syncResult
}