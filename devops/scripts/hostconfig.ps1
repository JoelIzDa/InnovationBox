param(
    [string]$applicationGroup,
    [string]$resourceGroup,
    [string]$displayName,
    [string]$hostPool
)

# Activate StartVMOnConnect
Write-Host "[Automation] Activating StartVMOnConnect on Host Pool: $hostPool"

### DEBUG
Write-Host "[Automation] Resource Group: $resourceGroup"
Write-Host "[Automation] Host Pool: $hostPool"
Write-Host "[Automation] Application Group: $applicationGroup"

Update-AzWvdHostPool -ResourceGroupName "$resourceGroup" `
                     -Name "$hostPool" `
                     -StartVMOnConnect:$true

 # DisplayName (source: https://learn.microsoft.com/en-us/azure/virtual-desktop/customize-feed-for-virtual-desktop-users?tabs=powershell)
Write-Host "[Automation] Change DisplayName from the Session Host to: $displayName"

 $display = @{
    ResourceGroupName = $resourceGroup
    ApplicationGroupName = $applicationGroup
    Name = "SessionDesktop"
    FriendlyName = $displayName
 }
 
Update-AzWvdDesktop @display

Write-Host "[Automation] AVD Configuration completed!"

$script = Get-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool

Write-Host "[Automation] The session host is now on status: $($script.Status)"

if ($script.Status -eq "Available") {
    Write-Host "[Automation] The session host is available for connections. Please start the user session within the Windows App."
} else {
    Write-Host "[Automation] The session host is not available for connections for now. Check the Azure portal for more details."
}
