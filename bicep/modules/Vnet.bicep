@description('Specifies the Azure location where the resource should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the VNet.')
param vnetname string

@description('Specifies the VNet Address Prefix.')
param addressprefix string = '10.0.1.0/24'

@description('Specifies the Subnet Address Prefix for the server subnet')
param defaultsubnetprefix string = '10.0.1.0/26'

resource vnet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetname
  location: location
  properties: {
      addressSpace: {
          addressPrefixes: [
              addressprefix
          ]
      }
      subnets: [
          {
              name: 'default'
              properties: {
                  addressPrefix: defaultsubnetprefix          
              }            
          }
      ]
  }
}

output id string = vnet.id
output defaultsubnetid string = '${vnet.id}/subnets/default'
