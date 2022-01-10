@minLength(3)
@maxLength(11)
param namePrefix string
param location string
param appServicePlanExtId string
param aseExtId string
param aseDomainName string
param appInsightsInstrKey string
param appInsightsEndpoint string
param storageConnectionString string

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
      alwaysOn: true
      appSettings: [
        {
          'name': 'APP_KIND'
          'value': 'workflowApp'
        }
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': appInsightsInstrKey
        }
        {
          'name': 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          'value': appInsightsEndpoint
        }
        {
          'name': 'AzureFunctionsJobHost__extensionBundle__id'
          'value': 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          'name': 'AzureFunctionsJobHost__extensionBundle__version'
          'value': '[1.*, 2.0.0)'
        }
        {
          'name': 'AzureWebJobsStorage'
          'value': storageConnectionString

        }
        {
          'name': 'FUNCTIONS_EXTENSION_VERSION'
          'value': '~3'
        }
        {
          'name': 'FUNCTIONS_WORKER_RUNTIME'
          'value': 'node'
        }
        {
          'name': 'WEBSITE_NODE_DEFAULT_VERSION'
          'value': '~12'
        }
        {
          'name': 'WEBSITE_VNET_ROUTE_ALL'
          'value': '1'
        }
      ]
    }
  }
}

output LogicAppName string = la.name
