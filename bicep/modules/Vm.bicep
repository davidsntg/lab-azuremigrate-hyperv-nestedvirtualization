param VmName string
param VmLocation string
param VmSize string
param VmOsType string 
param VmOsPublisher string 
param VmOsOffer string 
param VmOsSku string 
param VmOsVersion string 
param VmNicSubnetId string
param diagnosticsStorageUri string
param licenseType string = ''
param datadisksize int 
var VmOsDiskName = '${VmName}od01'
var VmDataDiskName = '${VmName}dd01'
var VmNicName = '${VmName}ni01'
var VmPipName = '${VmName}pip01'

param adminUsername string
param adminPassword string

resource Pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: VmPipName
  location: VmLocation
  sku: {
    name: 'Basic'
  }
  properties:{
    publicIPAllocationMethod:'Dynamic'
  }
}

resource Nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: VmNicName
  location: VmLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: VmNicSubnetId
          }
          primary: true
          publicIPAddress: {
            id: Pip.id
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
  dependsOn:[
    Pip
  ]
}

resource VirtualMachine 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: VmName
  location: VmLocation
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      osDisk: {
        name: VmOsDiskName
        createOption: 'FromImage'
        osType: VmOsType
        managedDisk:{
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: datadisksize
          lun: 0
          name: VmDataDiskName
          createOption: 'Empty'
        }
      ]
      imageReference: {
        publisher: VmOsPublisher
        offer: VmOsOffer
        sku: VmOsSku
        version: VmOsVersion
      }
    }
    osProfile: {
      computerName: VmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
        storageUri: diagnosticsStorageUri
      }
    }
    licenseType: licenseType
    networkProfile: {
      networkInterfaces: [
        {
          id: Nic.id
        }
      ]
    }
  }
  dependsOn:[
    Nic
  ]
}

output VirtualMachineId string = VirtualMachine.id
