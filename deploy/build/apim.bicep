@minLength(3)
@maxLength(11)
param namePrefix string
@minLength(1)
param publisherEmail string
@minLength(1)
param publisherName string
@allowed([
  'Basic'
  'Consumption'
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'
param skuCount int = 1
param location string = resourceGroup().location
param subnetResourceId string
param appInsightsName string
param appInsightsInstrKey string

var uniqueApimName = '${namePrefix}${uniqueString(resourceGroup().id)}apim'

resource apiManagement 'Microsoft.ApiManagement/service@2020-12-01' = {
  name: uniqueApimName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: subnetResourceId
    }

  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2020-12-01' = {
  name: appInsightsName
  parent: apiManagement
  properties: {
    loggerType: 'applicationInsights'
    description: 'Logger resources to APIM'
    credentials: {
      instrumentationKey: appInsightsInstrKey
    }
  }
}

output apimName string = apiManagement.name
output apimGwUrl string = apiManagement.properties.gatewayUrl
