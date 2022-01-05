param namePrefix string
param location string = resourceGroup().location

var virtualNetworkName = '${namePrefix}-vnet'
var nsgApimName = '${namePrefix}-vnet-apim-nsg'
var nsgAseName = '${namePrefix}-vnet-ase-nsg'

var subnet1Name = 'default'
var subnet2Name = 'apim' //seperate subnet for API Management
var subnet3Name = 'ase' //seperate subnet for the App Service Environment

resource nsgApim 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: nsgApimName
  location: location
  tags: {}
  properties: {
    securityRules: [
      {
        name: 'AllowAPIMPortal'
        properties: {
          access: 'Allow'
          destinationPortRange: '3443'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: ''
          sourceAddressPrefixes: [
            'string'
          ]
          sourcePortRange: '*'
        }
      }
    ]
  }
}

resource nsgAse 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: nsgAseName
  location: location
  tags: {}
  properties: {
    securityRules: // Security Rules
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: nsgApim.id == '' ? null : {
            id: nsgId
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: nsgAse.id == '' ? null : {
            id: nsgId
        }
      }
    ]
  }

  resource subnet1 'subnets' existing = {
    name: subnet1Name
  }

  resource subnet2 'subnets' existing = {
    name: subnet2Name
  }

  resource subnet3 'subnets' existing = {
    name: subnet3Name
  }
}

output virtualNetworkId string = virtualNetwork.id
output subnet2Name string = virtualNetwork::subnet2.name
output subnet2ResourceId string = virtualNetwork::subnet2.id
output subnet3Name string = virtualNetwork::subnet3.name
output subnet3ResourceId string = virtualNetwork::subnet3.id
