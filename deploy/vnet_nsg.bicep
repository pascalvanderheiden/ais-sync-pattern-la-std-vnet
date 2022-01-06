@minLength(3)
@maxLength(11)
param namePrefix string
param location string = resourceGroup().location

var virtualNetworkName = '${namePrefix}-vnet'
var subnet1Name = 'default'
var subnet2Name = 'apim' //seperate subnet for API Management
var subnet3Name = 'ase' //seperate subnet for the App Service Environment
var nsgSubnet2Name = '${namePrefix}-vnet-${subnet2Name}-nsg'
var nsgSubnet3Name = '${namePrefix}-vnet-${subnet3Name}-nsg'

resource nsgSubnet2 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: nsgSubnet2Name
  location: location
  tags: {}
  properties: {
    securityRules: [
      {
        name: 'AllowAPIMPortal'
        properties: {
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '3443'
            sourceAddressPrefix: 'ApiManagement'
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 2721
            direction: 'Inbound'
        }
      }
      {
          name: 'AllowVnetStorage'
          properties: {
              protocol: '*'
              sourcePortRange: '*'
              destinationPortRange: '443'
              sourceAddressPrefix: 'VirtualNetwork'
              destinationAddressPrefix: 'Storage'
              access: 'Allow'
              priority: 2731
              direction: 'Outbound'
          }
      }
      {
          name: 'AllowVnetMonitor'
          properties: {
              protocol: '*'
              sourcePortRange: '*'
              sourceAddressPrefix: 'VirtualNetwork'
              destinationAddressPrefix: 'AzureMonitor'
              access: 'Allow'
              priority: 2741
              direction: 'Outbound'
              destinationPortRanges: [
                  '1886'
                  '443'
              ]
          }
      }
      {
          name: 'AllowAPIMLoadBalancer'
          properties: {
              protocol: '*'
              sourcePortRange: '*'
              destinationPortRange: '6390'
              sourceAddressPrefix: 'AzureLoadBalancer'
              destinationAddressPrefix: 'VirtualNetwork'
              access: 'Allow'
              priority: 2751
              direction: 'Inbound'
          }
      }
      {
          name: 'AllowAPIMFrontdoor'
          properties: {
              protocol: 'Tcp'
              sourcePortRange: '*'
              destinationPortRange: '443'
              sourceAddressPrefix: 'AzureFrontDoor.Backend'
              destinationAddressPrefix: 'VirtualNetwork'
              access: 'Allow'
              priority: 2761
              direction: 'Inbound'
          }
      }
    ]
  }
}

resource nsgSubnet3 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: nsgSubnet3Name
  location: location
  tags: {}
  properties: {
    securityRules: []
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
          networkSecurityGroup: nsgSubnet2.id == '' ? null : {
            id: nsgSubnet2.id 
          }
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: nsgSubnet3.id == '' ? null : {
            id: nsgSubnet3.id
          }
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
