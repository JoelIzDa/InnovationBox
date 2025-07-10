param (
    [string]$resourceGroupName,
    [string]$vmName
)

Write-Host "[Automation] Checking VM status for '$vmName' in resource group '$resourceGroupName'..."
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Status
$vmStatus = $vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -ExpandProperty Code

if ($vmStatus -ne "PowerState/running") {
    Write-Host "[Automation] VM '$vmName' is not running. Starting VM..."
    Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

    do {
        Write-Host "[Automation] Waiting for VM '$vmName' to start..."
        Start-Sleep -Seconds 10
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Status
        $vmStatus = $vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -ExpandProperty Code
    } while ($vmStatus -ne "PowerState/running")

    Write-Host "[Automation] VM '$vmName' is now running."
} else {
    Write-Host "[Automation] VM '$vmName' is already running."
}
