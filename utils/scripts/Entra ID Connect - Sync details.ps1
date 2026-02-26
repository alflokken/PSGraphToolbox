write-host "onprem sync details" -f cyan
Invoke-GtGraphRequest -resourcePath "organization" -apiVersion "beta" -select "id,onPremisesSyncEnabled,onPremisesLastSyncDateTime,onPremisesLastPasswordSyncDateTime,onpremisesSyncStatus"

# legacy service account 
Write-Host "`nonprem sync service account details" -f cyan
Invoke-GtGraphRequest -resourcePath "users" -apiVersion "beta" -Filter "displayName eq 'On-Premises Directory Synchronization Service Account'" -select "userPrincipalName,createdDateTime,accountEnabled"

# app reg (spn)
Write-Host "`nconnect sync app registration details" -f cyan
Invoke-GtGraphRequest -resourcePath "applications" -apiVersion "beta" -Filter "startsWith(displayName,'ConnectSyncProvisioning')" -select "displayName,createdDateTime,appId"

# identify syncserver
#$syncServer = ($currentSyncAccount -replace "^Sync_" ) -replace "_.*$"