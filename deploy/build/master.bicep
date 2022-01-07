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

output storageName string = stgModule.outputs.storageName
output storageEndpoint string = stgModule.outputs.storageEndpoint

// Create a Virtual Network & Network Sercurity Groups
module vnetModule '../build/vnet_nsg.bicep' = {
  name: 'vnetDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
  }
}

output subnetNameApim string = vnetModule.outputs.subnet2Name
var vnetId = vnetModule.outputs.virtualNetworkId
var subnetResourceIdApim = vnetModule.outputs.subnet2ResourceId
var subnetNameAse = vnetModule.outputs.subnet3Name

// Create Application Insights & Log Analytics Workspace
module appInsightsModule '../build/appInsights_loganalytics.bicep' = {
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
output logAnalyticsWorkspaceName string = appInsightsModule.outputs.logAnalyticsWorkspaceName

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
    subnetResourceId: subnetResourceIdApim
  }
}

output apimName string = apimModule.outputs.apimName
var apimGwUrl = apimModule.outputs.apimGwUrl

// Create Frontdoor
module frontDoorModule '../build/frontdoor_waf.bicep' = {
  name: 'frontDoorDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    apimGwUrl: apimGwUrl
  }
}

output frontDoorName string = frontDoorModule.outputs.frontDoorName
output frontDoorWafName string = frontDoorModule.outputs.frontDoorWafName

// Create App Service Environment V3 & App Service Plan
module aseModule '../build/asev3_asp.bicep' = {
  name: 'aseDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
    virtualNetworkId: vnetId
    subnetName: subnetNameAse
  }
}

output aseName string = aseModule.outputs.aseName
var aseDomainName = aseModule.outputs.aseDomainName
var aseExtId = aseModule.outputs.aseExtId
output appServicePlanName string = aseModule.outputs.appServicePlanName
var appServicePlanExtId = aseModule.outputs.appServicePlanExtId

// Create Logic Apps (Standard)
module logicAppModule '../build/logicapp.bicep' = {
  name: 'logicAppDeploy'
  scope: newRG
  params: {
    namePrefix: namePrefix
    location: location
    appServicePlanExtId: appServicePlanExtId
    aseExtId: aseExtId
    aseDomainName: aseDomainName
  }
}

output logicAppName string = logicAppModule.outputs.LogicAppName
