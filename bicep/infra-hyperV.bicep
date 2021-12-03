// Resource Group 1: Nested Hyper-V virtualization

param nestedvirtuaLocation string = 'westeurope'
param nestedvirtuaVnetName string = 'vnet-hyperv'
param nestedvirtuaVnetAddressSpace string = '10.221.0.0/24'
param nestedvirtuaDefaultSubnet string = '10.221.0.0/24'
param nestedvirtualStorageAccountName string = 'diagstoragenestedvirtua'

// VMs
param VmSize string = 'Standard_E8s_v4'
param adminUsername string = 'microsoft'
param adminPassword string = 'Microsoft=1Microsoft=1'
param VmOsType string = 'Windows' 
param VmOsPublisher string = 'MicrosoftWindowsServer' 
param VmOsOffer string = 'WindowsServer' 
param VmOsSku string = '2019-Datacenter' 
param VmOsVersion string = 'latest'

module vnet './modules/Vnet.bicep' = {
  name: 'vnet'
  scope: resourceGroup()
  params: {
    location: nestedvirtuaLocation
    vnetname: nestedvirtuaVnetName
    addressprefix: nestedvirtuaVnetAddressSpace
    defaultsubnetprefix: nestedvirtuaDefaultSubnet
  }
}

module diagnosticstorageaccount './modules/StorageAccount.bicep' = {
  name: 'diagnosticstorageaccount' 
  scope: resourceGroup()
  params:{
    storageAccountName: nestedvirtualStorageAccountName
    location: nestedvirtuaLocation
    skuName: 'Standard_LRS'
  }
}

module hyperv_vm './modules/Vm.bicep' = {
  name: 'hyperv_vm'
  scope: resourceGroup()
  params: {
    VmName: 'hyperv'
    VmLocation: nestedvirtuaLocation
    VmSize: VmSize
    VmOsType: VmOsType 
    VmOsPublisher: VmOsPublisher 
    VmOsOffer: VmOsOffer 
    VmOsSku: VmOsSku
    VmOsVersion: VmOsVersion
    VmNicSubnetId: vnet.outputs.defaultsubnetid
    adminUsername: adminUsername 
    adminPassword: adminPassword
    diagnosticsStorageUri: diagnosticstorageaccount.outputs.blobUri
    licenseType: 'Windows_Server'
    datadisksize: 1024
  }
  dependsOn:[
    vnet
    diagnosticstorageaccount
  ]
}
