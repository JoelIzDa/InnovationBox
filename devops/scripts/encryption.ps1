# This script registers the encryption at host feature
Write-Host "[Automation] Checking if EncryptionAtHost is registered..."
$feature = Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
if ($feature.RegistrationState -eq "Registered") {
    Write-Host "[Automation] EncryptionAtHost is already registered."
} else {
    Write-Host "[Automation] Registering EncryptionAtHost Feature..."
    Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"

    Write-Host "[Automation] Waiting for the feature to be activated..."
    do {
        Start-Sleep -Seconds 5
        $feature = Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
        Write-Host "[Automation] Current status: $($feature.RegistrationState)"
    } while ($feature.RegistrationState -ne "Registered")

    Write-Host "[Automation] EncryptionAtHost Feature successfully registered."
}
