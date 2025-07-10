// scope
targetScope = 'resourceGroup'

// parameters
param area string
param appname string
param addressPrefix string
param num string
param wltype string
param da string

@minLength(1)
@maxLength(90)
param nwrgName string = '${wltype}-${da}-${area}-${appname}-nwrg-${num}'

// network module
module network './templates/virtualNetwork.bicep' = {
  name: 'networkModule'
  scope: resourceGroup(nwrgName)
  params: {
    area: area
    appname: appname
    addressPrefix: addressPrefix
    num: num
    wltype: wltype
    da: da
  }
}

// output
output nsgId string = network.outputs.nsgId
output vnetId string = network.outputs.vnetId
output subnetId string = network.outputs.subnetId
