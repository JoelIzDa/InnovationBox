// scope
targetScope = 'resourceGroup'

// parameters
param location string
param avdlocation string = 'westeurope'
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
param tokenexpirationtime string = utcNow()
param shutdownTime string
param diskSizeGB int
param storageAccountType string

param aCUAgroupFATId string
param wvdspnId string

// parameter validation (source: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules)
@minLength(3)
@maxLength(64)
param hostpoolName string = '${wltype}-${da}-${area}-${appname}-pl-${num}'

@minLength(1)
@maxLength(80)
param publicIpsName string = '${wltype}-${da}-${area}-${appname}-ip-${num}'

@minLength(1)
@maxLength(80)
param networkInterfacesName string = '${wltype}-${da}-${area}-${appname}-nic-${num}'

@minLength(1)
@maxLength(15)
param virtualMachinesName string = '${appname}-${num}'

@minLength(1)
@maxLength(128)
param autoShutdownConfigName string = 'shutdown-computevm-${appname}-${num}' // Azure standard name (Can't be changed)

@minLength(1)
@maxLength(64)
param aadLoginExtensionName string = '${wltype}-${da}-${area}-${appname}-AADJoin-${num}'

@minLength(3)
@maxLength(64)
param applicationGroupName string = '${wltype}-${da}-${area}-${appname}-ag-${num}'

@minLength(3)
@maxLength(64)
param workspaceName string = '${wltype}-${da}-${area}-${appname}-ws-${num}'

@minLength(1)
@maxLength(80)
param osDiskName string = 'onln-oiz-${area}-${appname}-OsDisk-${num}'

// role-ID (always the same)
param vmloginroleResourceId string = 'fb879df8-f326-4884-b1cf-06f3ad86be52'
param agroleResourceId string = '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
param powerroleResourceId string = '40c5ff49-9181-41f8-ae61-143b0e78555e'
param controleResourceId string = 'a959dbd1-f747-45e3-8ba6-dd80f235f97c'

// output parameters from network module
param subnetId string
param nsgId string

// hostpool
resource hostpool 'Microsoft.DesktopVirtualization/hostpools@2024-04-08-preview' = {
  name: hostpoolName
  location: avdlocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedPrivateUDP: 'Default'
    directUDP: 'Default'
    publicUDP: 'Default'
    relayUDP: 'Default'
    managementType: 'Standard'
    publicNetworkAccess: 'Enabled'
    hostPoolType: 'Pooled'
    customRdpProperty: 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;targetisaadjoined:i:1;enablerdsaadauth:i:1;'
    maxSessionLimit: 10
    registrationInfo: {
      expirationTime: dateTimeAdd(tokenexpirationtime, 'PT12H')
      registrationTokenOperation: 'none'
    }
    loadBalancerType: 'DepthFirst'
    validationEnvironment: false
    ring: 1
    preferredAppGroupType: 'Desktop'
  }
}

// network resources
resource publicIps 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpsName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource networkInterfaces 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: networkInterfacesName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIps.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

// virtual machine (Session Host)
resource virtualMachines 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachinesName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmsize
    }
    storageProfile: {
      imageReference: {
        publisher: imagepublisher
        offer: imageoffer
        sku: imagesku
        version: imageversion
      }
      osDisk: {
        osType: 'Windows'
        name: osDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: storageAccountType
        }
        deleteOption: 'Detach'
        diskSizeGB: diskSizeGB
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: appname
      adminUsername: adminusername
      adminPassword: adminpassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    securityProfile: {
      encryptionAtHost: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces.id
        }
      ]
    }
  }
}

// role assignments
resource vmRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(virtualMachines.id, aCUAgroupFATId, vmloginroleResourceId)
  scope: virtualMachines
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', vmloginroleResourceId) // Virtual Machine User Login -> aCUA-oiz-ibox-FaT
    principalId: aCUAgroupFATId
    principalType: 'Group' // oder 'User'
  }
}

resource vmContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(virtualMachines.id, aCUAgroupFATId, controleResourceId) // VM Contributor Role ID
  scope: virtualMachines
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', controleResourceId) // Virtual Machine Contributor -> aCUA-oiz-ibox-FaT
    principalId: aCUAgroupFATId
    principalType: 'Group'
  }
}

resource assignPowerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(virtualMachines.id, wvdspnId, powerroleResourceId)
  scope: virtualMachines
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', powerroleResourceId) // Desktop Virtualization Power On Off Contributor -> Windows Virtual Desktop / Azure Virtual Desktop
    principalId: wvdspnId
    principalType: 'ServicePrincipal'
  }
}


// virtual machine extensions
resource autoShutdownConfig 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: autoShutdownConfigName
  location: location
  properties: {
    status: 'Enabled'
    dailyRecurrence: {
      time: shutdownTime // shutdown time
    }
    timeZoneId: 'W. Europe Standard Time'
    taskType: 'ComputeVmShutdownTask'
    targetResourceId: virtualMachines.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

resource aadLoginExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  name: aadLoginExtensionName
  location: location
  parent: virtualMachines
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      Licensing: 'Confirmed'
      mdmId: ''
      tenantId: tenantId
    }
  }
}

// application group
resource applicationGroup 'Microsoft.DesktopVirtualization/applicationgroups@2024-08-08-preview' = {
  name: applicationGroupName
  location: avdlocation
  kind: 'Desktop'
  properties: {
    showInFeed: true
    hostPoolArmPath: hostpool.id
    friendlyName: 'Innovationsbox'
    applicationGroupType: 'Desktop'
  }
}

resource desktopVirtualizationUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(applicationGroup.id, aCUAgroupFATId, agroleResourceId)
  scope: applicationGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', agroleResourceId) // Desktop Virtualization User
    principalId: aCUAgroupFATId
    principalType: 'Group'
  }
}

// workspace
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: workspaceName
  location: avdlocation
  properties: {
    publicNetworkAccess: 'Enabled'
    applicationGroupReferences: [applicationGroup.id]
  }
}

// Output für Session Host Registrierung
output hostpoolName string = hostpool.name
output vmName string = virtualMachines.name
output applicationGroupName string = applicationGroup.name
output workspaceName string = workspace.name
