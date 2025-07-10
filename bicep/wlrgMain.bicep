// scope
targetScope = 'resourceGroup'

// parameters
param location string
param appname string
param area string
param num string
param tenantId string
param wltype string
param da string

@secure()
param adminpassword string

param adminusername string
param vmsize string
param imagesku string
param imageoffer string
param imagepublisher string
param imageversion string
param shutdownTime string
param diskSizeGB int
param storageAccountType string

param aCUAgroupFATId string
param wvdspnId string

@minLength(1)
@maxLength(90)
param wlrgName string = '${wltype}-${da}-${area}-${appname}-wlrg-${num}'

// output parameters from network module
param subnetId string
param nsgId string

// workload module
module workload './templates/workloadResources.bicep' = {
  name: 'workloadModule'
  scope: resourceGroup(wlrgName)
  params: {
    num: num
    area: area
    appname: appname
    location: location
    adminusername: adminusername
    adminpassword: adminpassword
    imagesku: imagesku
    imageoffer: imageoffer
    imagepublisher: imagepublisher
    imageversion: imageversion
    subnetId: subnetId
    vmsize: vmsize
    nsgId: nsgId
    tenantId: tenantId
    aCUAgroupFATId: aCUAgroupFATId
    wvdspnId: wvdspnId
    wltype: wltype
    da: da
    shutdownTime: shutdownTime
    diskSizeGB: diskSizeGB
    storageAccountType: storageAccountType
  }
}

output vmName string = workload.outputs.vmName
output hostpoolName string = workload.outputs.hostpoolName
output applicationGroupName string = workload.outputs.applicationGroupName
output workspaceName string = workload.outputs.workspaceName
