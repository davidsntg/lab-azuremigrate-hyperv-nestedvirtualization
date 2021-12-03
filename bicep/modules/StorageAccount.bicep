param storageAccountName string
param location string
param skuName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties:{
    networkAcls:{
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        file:{
          keyType: 'Account'
          enabled: true
        }
        blob:{
          keyType: 'Account'
          enabled: true
        }
      }
    }
  }
}

output blobUri string = storageAccount.properties.primaryEndpoints.blob
