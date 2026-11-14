function Get-GtEntraIdP1P2LicenseUtilization {
    Invoke-GtGraphRequest "/reports/azureADPremiumLicenseInsight" -ApiVersion beta
}