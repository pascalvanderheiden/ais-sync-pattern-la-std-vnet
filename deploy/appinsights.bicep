@minLength(3)
@maxLength(11)
param namePrefix string
param location string = resourceGroup().location

var appInsightsName = '${namePrefix}-ai'

resource appinsights 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output appInsightsName string = appinsights.name
output appInsightsId string = appinsights.id
output appInsightsInstrKey string = appinsights.properties.InstrumentationKey
