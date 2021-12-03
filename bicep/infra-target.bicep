// Resource Group 2: Target Resource Group for Azure Migrate

param targetLocation string = 'northeurope'
param targetStorageAccountName string = 'targetreplicatesa'
param targetVnetName string = 'vnettarget'
param targetVnetAddressSpace string = '10.233.0.0/16'
param targetVnetDefaultSubnet string = '10.233.1.0/24'



module vnet './modules/Vnet.bicep' = {
  name: 'vnet'
  scope: resourceGroup()
  params: {
    location: targetLocation
    vnetname: targetVnetName
    addressprefix: targetVnetAddressSpace
    defaultsubnetprefix: targetVnetDefaultSubnet
  }
}

module storageaccount './modules/StorageAccount.bicep' = {
  name: 'storageaccount' 
  scope: resourceGroup()
  params:{
    storageAccountName: targetStorageAccountName
    location: targetLocation
    skuName: 'Standard_LRS'
  }
}
