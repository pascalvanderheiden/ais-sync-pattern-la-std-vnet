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
module stgModule '../build/storage.bicep' = {
  name: 'storageDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
  }
}

// Create a Virtual Network & Network Sercurity Groups
module vnetModule '../build/vnet_nsg.bicep' = {
  name: 'vnetDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
  }
}

// Create Application Insights & Log Analytics Workspace
module appInsightsModule '../build/appinsights_loganalytics.bicep' = {
  name: 'appInsightsDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
  }
}

// Create API Management instance
module apimModule '../build/apim.bicep' = {
  name: 'apimDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    publisherEmail: 'me@example.com'
    publisherName: 'Me Company Ltd.'
    sku: 'Developer'
    location: location
    subnetResourceId: vnetModule.outputs.subnet2ResourceId
    appInsightsName: appInsightsModule.outputs.appInsightsName
    appInsightsInstrKey: appInsightsModule.outputs.appInsightsInstrKey
  }
  dependsOn:[
    appInsightsModule
    vnetModule
  ]
}

// Create Frontdoor
module frontDoorModule '../build/frontdoor_waf.bicep' = {
  name: 'frontDoorDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    apimGwUrl: '${apimModule.outputs.apimName}.azure-api.net'
  }
  dependsOn:[
    apimModule
    vnetModule
  ]
}

// Create App Service Environment & App Service Plan
module aseModule '../build/ase_asp.bicep' = {
  name: 'aseDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
    virtualNetworkId: vnetModule.outputs.virtualNetworkId
    subnetName: vnetModule.outputs.subnet3Name
  }
  dependsOn:[
    vnetModule
  ]
}

// Create Logic Apps (Standard)
module logicAppModule '../build/logicapp.bicep' = {
  name: 'logicAppDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
    appServicePlanExtId: aseModule.outputs.appServicePlanExtId
    aseExtId: aseModule.outputs.aseExtId
    aseDomainName: aseModule.outputs.aseDomainName
    appInsightsInstrKey: appInsightsModule.outputs.appInsightsInstrKey
    appInsightsEndpoint: appInsightsModule.outputs.appInsightsEndpoint
    storageEndpoint: stgModule.outputs.storageEndpoint
  }
  dependsOn:[
    aseModule
    stgModule
    appInsightsModule
  ]
}
