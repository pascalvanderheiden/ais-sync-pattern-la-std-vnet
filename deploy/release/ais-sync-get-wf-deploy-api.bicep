targetScope = 'resourceGroup'

param apimName string
param appInsightsName string
param logicAppName string
param workflowName string
param workflowSigNamedValue string
param frontDoorIdNamedValue string
param apiName string
param apiPath string
var apiPolicy = '<policies><inbound><base /><set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" /><set-backend-service backend-id="${logicAppName}" /><rewrite-uri template="${workflowName}/triggers/manual/invoke?api-version=2020-05-01-preview" /><set-query-parameter name="sig" exists-action="append"><value>{{${workflowSigNamedValue}}}</value></set-query-parameter></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
var apiPolicyFrontDoor = '<policies><inbound><base /><check-header name="X-Azure-FDID" failed-check-httpcode="403" failed-check-error-message="Unauthorized" ignore-case="true"><value>{{${frontDoorIdNamedValue}}}</value></check-header></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'

resource apiManagement 'Microsoft.ApiManagement/service@2020-12-01' existing = {
  name: apimName
}

resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2020-12-01' existing = {
  name: '${apimName}/${appInsightsName}'
}

resource logicApp 'Microsoft.Web/sites@2021-02-01' existing = {
  name: logicAppName
}

resource apimApi 'Microsoft.ApiManagement/service/apis@2020-12-01' = {
  name: toLower(apiName)
  parent: apiManagement
  properties: {
    path: apiPath
    apiRevision: '1'
    displayName: apiName
    subscriptionRequired: false
    protocols: [
      'https'
    ]
  }
}

resource logicAppBackend 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  name: logicAppName
  parent: apiManagement
  properties: {
    description: logicAppName
    url: 'https://${logicApp.properties.defaultHostName}/api'
    protocol: 'http'
    credentials: {
      query: {
        sp: [
          '%2Ftriggers%2Fmanual%2Frun'
        ]
        sv: [
          '1.0'
        ]
      }
      header: {}
    }
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

resource apiOperationGet 'Microsoft.ApiManagement/service/apis/operations@2020-06-01-preview' = {
  name: 'GET'
  parent: apimApi
  properties: {
    displayName: 'Get'
    method: 'GET'
    urlTemplate: '/get'
    description: 'Calling the Logic App from the ASEV3'
  }
}

resource apiGetPolicies 'Microsoft.ApiManagement/service/apis/operations/policies@2020-12-01' = {
  name: 'policy'
  parent: apiOperationGet
  properties: {
    value: apiPolicy
    format: 'rawxml'
  }
  dependsOn: [
    logicAppBackend
  ]
}

resource apiAllOppPolicies 'Microsoft.ApiManagement/service/apis/policies@2020-12-01' = {
  name: 'policy'
  parent: apimApi
  properties: {
    value: apiPolicyFrontDoor
    format: 'rawxml'
  }
}

resource apiMonitoring 'Microsoft.ApiManagement/service/apis/diagnostics@2020-06-01-preview' = {
  name: 'applicationinsights'
  parent: apimApi
  properties: {
    alwaysLog: 'allErrors'
    loggerId: apiManagementLogger.id  
    logClientIp: true
    httpCorrelationProtocol: 'W3C'
    verbosity: 'verbose'
    operationNameFormat: 'Url'
  }
}
