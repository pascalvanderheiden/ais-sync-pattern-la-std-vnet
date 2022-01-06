// set the target scope for this file
targetScope = 'subscription'

@minLength(3)
@maxLength(11)

// set the params
param namePrefix string
param location string = deployment().location

// set local var
var resourceGroupName = '${namePrefix}-rg'

// Create a Resource Group
resource newRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

// Create a Storage Account
module stgModule '../deploy/storage.bicep' = {
  name: 'storageDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
  }
}

output storageName string = stgModule.outputs.storageName
output storageEndpoint string = stgModule.outputs.storageEndpoint

// Create a Virtual Network
module vnetModule '../deploy/vnet_nsg.bicep' = {
  name: 'vnetDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
  }
}

output vnetId string = vnetModule.outputs.virtualNetworkId
output subnetNameApim string = vnetModule.outputs.subnet2Name
var subnetResourceIdApim = vnetModule.outputs.subnet2ResourceId
output subnetNameAse string = vnetModule.outputs.subnet3Name

// Create Application Insights
module appInsightsModule '../deploy/appInsights.bicep' = {
  name: 'appInsightsDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
  }
}

output appInsightsName string = appInsightsModule.outputs.appInsightsName
output appInsightsId string = appInsightsModule.outputs.appInsightsId
output appInsightsInstrKey string = appInsightsModule.outputs.appInsightsInstrKey

// Create API Management instance
module apimModule '../deploy/apim.bicep' = {
  name: 'apimDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    publisherEmail: 'me@example.com'
    publisherName: 'Me Company Ltd.'
    sku: 'Developer'
    location: location
    subnetResourceId: subnetResourceIdApim
  }
}

