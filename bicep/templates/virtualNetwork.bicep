// scope
targetScope = 'resourceGroup'

// parameters
param appname string
param area string
param num string
param addressPrefix string
param wltype string
param da string

@minLength(1)
@maxLength(80)
param subnetName string = '${wltype}-${da}-${area}-${appname}-snet-${num}' // name of the new subnet resource

param vnetName string = '${wltype}-${da}-${area}-${appname}-vnet-${num}' // name of the existing virtual network resource

param nsgName string = '${wltype}-${da}-${area}-${appname}-nsg-${num}' // name of the existing network security group resource

param routeTablesName string = '${wltype}-${da}-${area}-${appname}-rt-${num}' // name of the existing route table resource

// existing network resources
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' existing = {
  name: nsgName
}

resource routeTables 'Microsoft.Network/routeTables@2024-05-01' existing = {
  name: routeTablesName
}

// new subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet // references the existing virtual network
  name: subnetName
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
    routeTable: {
      id: routeTables.id
    }
  }
}

// outputs
output nsgId string = nsg.id
output vnetId string = vnet.id
output subnetId string = subnet.id
