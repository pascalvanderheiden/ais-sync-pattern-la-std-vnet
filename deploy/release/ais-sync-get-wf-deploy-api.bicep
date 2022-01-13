targetScope = 'resourceGroup'

param apimName string
param logicAppName string
param workflowName string
//param workflowSASkey string
param workflowSigNamedValue string
param apiName string
param apiPath string
var apiPolicy = '<!--\r\n    IMPORTANT:\r\n    - Policy elements can appear only within the <inbound>, <outbound>, <backend> section elements.\r\n    - To apply a policy to the incoming request (before it is forwarded to the backend service), place a corresponding policy element within the <inbound> section element.\r\n    - To apply a policy to the outgoing response (before it is sent back to the caller), place a corresponding policy element within the <outbound> section element.\r\n    - To add a policy, place the cursor at the desired insertion point and select a policy from the sidebar.\r\n    - To remove a policy, delete the corresponding policy statement from the policy document.\r\n    - Position the <base> element within a section element to inherit all policies from the corresponding section element in the enclosing scope.\r\n    - Remove the <base> element to prevent inheriting policies from the corresponding section element in the enclosing scope.\r\n    - Policies are applied in the order of their appearance, from the top down.\r\n    - Comments within policy elements are not supported and may disappear. Place your comments between policy elements or at a higher level scope.\r\n-->\r\n<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n    <set-backend-service backend-id="${logicAppName}" />\r\n    <rewrite-uri template="${workflowName}/triggers/manual/invoke?api-version=2020-05-01-preview" />\r\n    <set-query-parameter name="sig" exists-action="append">\r\n      <value>{{${workflowSigNamedValue}}}</value>\r\n    </set-query-parameter>\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'


resource apiManagement 'Microsoft.ApiManagement/service@2020-12-01' existing = {
  name: apimName
}

resource logicApp 'Microsoft.Web/sites@2021-02-01' existing = {
  name: logicAppName
}

resource apimApi 'Microsoft.ApiManagement/service/apis@2020-12-01' = {
  name: apiName
  parent: apiManagement
  properties: {
    path: apiPath
    apiRevision: '1'
    displayName: apiName
    description: apiName
    subscriptionRequired: false
    protocols: [
      'https'
    ]
  }
}
/*
//deploying by added the SAS key into the script
resource apim 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: '${workflowName}-sig'
  parent: apiManagement
  properties: {
    displayName: '${workflowName}-sig'
    secret: true
    value: workflowSASkey
  }
}
*/

resource logicAppBackend 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  name: logicAppName
  parent: apiManagement
  properties: {
    description: ''
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

resource apiGetPolicies 'Microsoft.ApiManagement/service/apis/policies@2020-12-01' = {
  name: '${apiOperationGet.name}/policy'
  properties: {
    value: apiPolicy
  }
}
