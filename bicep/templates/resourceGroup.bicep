// scope
targetScope = 'subscription'

// parameters
param location string
param appname string
param area string
param num string
param wltype string
param da string

@minLength(1)
@maxLength(90)
param wlrgName string = '${wltype}-${da}-${area}-${appname}-wlrg-${num}' // name of the new workload resource group

param bsrgName string = '${wltype}-${da}-${area}-${appname}-nwrg-${num}' // name of the existing networking resource group

// existing resource groups
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: bsrgName
}

// new resource groups
resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: wlrgName
  location: location
}

// outputs
output networkResourceGroupId string = networkResourceGroup.id
output workloadResourceGroupName string = workloadResourceGroup.name
output networkResourceGroupName string = networkResourceGroup.name
