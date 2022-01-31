// set the target scope for this file
targetScope = 'subscription'

@minLength(3)
@maxLength(11)

// set the params
param namePrefix string
param location string = deployment().location

// set local var
var resourceGroupName = '${namePrefix}-rg'
var logicAppName = '${namePrefix}-la'

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
    fileShareName: logicAppName
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
    apimName: apimModule.outputs.apimName
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
    virtualNetworkId: vnetModule.outputs.subnet3ResourceId
    subnetName: vnetModule.outputs.subnet3Name
  }
  dependsOn:[
    vnetModule
  ]
}

// Create Private DNS Zone
module privDnsModule '../build/dns.bicep' = {
  name: 'privDNSDeploy'
  scope: newRG
  params: {
    aseDomainName: aseModule.outputs.aseDomainName
    virtualNetworkId: vnetModule.outputs.virtualNetworkId
    aseIp: '10.0.2.4' //fixed, first assignment within vnet delegated to ASEv3
  }
  dependsOn:[
    aseModule
    vnetModule
  ]
}

// Create Logic Apps (Standard)
module logicAppModule '../build/logicapp.bicep' = {
  name: 'logicAppDeploy'
  scope: newRG
  params: {
    logicAppName: logicAppName
    location: location
    appServicePlanExtId: aseModule.outputs.appServicePlanExtId
    aseExtId: aseModule.outputs.aseExtId
    aseDomainName: aseModule.outputs.aseDomainName
    appInsightsInstrKey: appInsightsModule.outputs.appInsightsInstrKey
    appInsightsEndpoint: appInsightsModule.outputs.appInsightsEndpoint
    storageConnectionString: stgModule.outputs.storageConnectionString
  }
  dependsOn:[
    aseModule
    stgModule
    appInsightsModule
    privDnsModule
  ]
}
