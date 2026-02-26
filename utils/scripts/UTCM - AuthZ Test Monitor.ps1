Connect-MgGraph -Scopes "Application.ReadWrite.All"

# add Unified Tenant Configuration Management service principal
$utcmSpn = Invoke-GraphRequest -Uri "v1.0/servicePrincipals" -Method POST -Body @{ appId = "03b07b79-c5bc-4b5e-9bfa-13acf4a99998" }

# assign API permissions to 
$graphSpn = Invoke-GraphRequest -Uri "v1.0/servicePrincipals?`$filter=appId eq '00000003-0000-0000-c000-000000000000'&`$select=id,appRoles" -Method GET -OutputType PSObject | select -ExpandProperty value 
Invoke-GraphRequest -Uri "v1.0/servicePrincipals/$($utcmSpn.id)/appRoleAssignedTo" -Method POST -Body @{
    principalId = $utcmSpn.id
    resourceId = $graphSpn.id
    appRoleId = "246dd0d5-5bd0-4def-940b-0421030a5b68" # Policy.Read.All
}

Connect-MgGraph -scopes "ConfigurationManagement.ReadWrite.All"

# Create snapshot for authorization policies
$response = Invoke-GraphRequest -Uri "beta/admin/configurationManagement/configurationSnapshots/createSnapshot" -Method POST -Body @{
    displayName = "Authorization Policy Snapshot"
    description = "This is a demo of the Snapshot feature for authorizationPolicies"
    resources = @(
        "microsoft.entra.authorizationPolicy"
    )
}

# check job status
$job = Invoke-MgGraphRequest -uri "beta/admin/configurationManagement/configurationSnapshotJobs/$($response.id)" 

# retrieve snapshot result
$snapshot = Invoke-MgGraphRequest -uri $job.resourceLocation

# create a new monitor with the snapshot
$monitor = Invoke-MgGraphRequest -Uri "beta/admin/configurationManagement/configurationMonitors" -Method POST -Body @{
    displayName = "AuthZ Policy Monitor"
    baseline = @{
        displayName = $snapshot.displayName
        description = $snapshot.description
        resources   = @($snapshot.resources)
    }
}
# check monitor status
Invoke-MgGraphRequest -Uri "beta/admin/configurationManagement/configurationMonitoringResults?`$filter=monitorId eq '$($monitor.id)'" -OutputType PSObject | Select -expand Value

# configuration drift api
$driftResults = Invoke-MgGraphRequest -Uri "beta/admin/configurationManagement/configurationDrifts?`$filter=monitorId eq '$($monitor.id)'" -OutputType PSObject | Select -expand Value

# get monitors
$monitors = Invoke-MgGraphRequest -Uri "beta/admin/configurationManagement/configurationMonitors?`$select=id,displayName" -OutputType PSObject  | select -ExpandProperty value