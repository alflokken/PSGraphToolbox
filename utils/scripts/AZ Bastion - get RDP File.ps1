$ResourceGroupName = "resource-group-name"
$bastionDnsName = "bastion-dns-name"
$subscriptionId = "subscription-id"
[string[]]$hosts = "server1","server2","server3"

$at = (az account get-access-token | ConvertFrom-Json).accessToken;

$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/"

$hosts |% { 
    $rdpFile = Invoke-RestMethod -Method Get -Uri "https://$BastionDnsName/api/rdpfile?resourceId=$resourceId$_&format=rdp&enablerdsaad=true" -Headers @{ 'Content-Type'  = 'application/json'; 'Authorization' = "Bearer $at" }
    $rdpFile = $rdpFile -replace("use multimon:i:1","")
    $rdpFile | Out-File .\$_.rdp -Force
}