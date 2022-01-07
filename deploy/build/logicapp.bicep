@minLength(3)
@maxLength(11)
param namePrefix string
param location string
param appServicePlanExtId string
param aseExtId string
param aseDomainName string
param appInsightsInstrKey string
param appInsightsEndpoint string
param storageEndpoint string

var logicAppName = '${namePrefix}-la'
var logicAppEnabledState = true

resource la 'Microsoft.Web/sites@2021-02-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
      type: 'SystemAssigned'
  }
  properties: {
    enabled: logicAppEnabledState
    hostNameSslStates: [
      {
          name: '${logicAppName}.${aseDomainName}'
          sslState: 'Disabled'
          hostType: 'Standard'
      }
      {
          name: '${logicAppName}.scm.${aseDomainName}'
          sslState: 'Disabled'
          hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlanExtId
    hostingEnvironmentProfile: {
      id: aseExtId
    }
    siteConfig: {
      appSettings: [
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': appInsightsInstrKey
        }
        {
          'name': 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          'value': appInsightsEndpoint
        }
        {
          'name': 'AzureWebJobsStorage'
          'value': storageEndpoint
        }
      ]
    }
  }
}

output LogicAppName string = la.name
