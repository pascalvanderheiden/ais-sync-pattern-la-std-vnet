@minLength(3)
@maxLength(11)
param namePrefix string
param apimGwUrl string
param apimName string

var frontDoorEnabledState = true
var healthProbe1EnabledState = true
var frontDoorWafEnabledState = true
var frontDoorWafMode = 'Detection'

var frontDoorName = '${namePrefix}-fd'
var frontDoorWafName = '${namePrefix}policywaf'
var frontDoorNameLower = toLower(frontDoorName)

var backendPool1Name = '${frontDoorNameLower}-apimBackendPool1'
var healthProbe1Name = '${frontDoorNameLower}-apimHealthProbe1'
var frontendEndpoint1Name = '${frontDoorNameLower}-apimFrontendEndpoint1'
var loadBalancing1Name = '${frontDoorNameLower}-apimLoadBalancing1'
var routingRule1Name = '${frontDoorNameLower}-apimRoutingRule1'

var frontendEndpoint1hostName = '${frontDoorNameLower}.azurefd.net'
var backendPool1TargetUrl = apimGwUrl
var frontDoorIdNamedValue = '${frontDoorNameLower}-id'

resource apiManagement 'Microsoft.ApiManagement/service@2020-12-01' existing = {
  name: apimName
}

resource resAzFd 'Microsoft.Network/frontdoors@2020-01-01' = {
  name: frontDoorNameLower
  location: 'Global'
  properties: {
    enabledState: frontDoorEnabledState ? 'Enabled' : 'Disabled'
    friendlyName: frontDoorNameLower
    frontendEndpoints: [
      {
        name: frontendEndpoint1Name
        properties: {
          hostName: frontendEndpoint1hostName
          sessionAffinityEnabledState: 'Disabled'
          sessionAffinityTtlSeconds: 0
          webApplicationFirewallPolicyLink: {
            id: '${resAzFdWaf.id}'
          }
        }
      }
    ]
    backendPoolsSettings: {
      enforceCertificateNameCheck: 'Enabled'
      sendRecvTimeoutSeconds: 30
    }
    backendPools: [
      {
        name: backendPool1Name
        properties: {
          backends: [
            {
              address: backendPool1TargetUrl
              backendHostHeader: backendPool1TargetUrl
              enabledState: 'Enabled'
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 50
            }
          ]
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorNameLower, healthProbe1Name)
          }
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorNameLower, loadBalancing1Name)
          }
        }
      }
    ]
    healthProbeSettings: [
      {
        name: healthProbe1Name
        properties: {
            path: '/status-0123456789abcdef'
            protocol: 'Https'
            intervalInSeconds: 30
            enabledState: healthProbe1EnabledState ? 'Enabled' : 'Disabled'
            healthProbeMethod: 'GET'
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: loadBalancing1Name
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    routingRules: [
      {
        name: routingRule1Name
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/FrontendEndpoints', frontDoorNameLower, frontendEndpoint1Name)
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          enabledState: 'Enabled'
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/BackendPools', frontDoorNameLower, backendPool1Name)
            }
          }
        }
      }
    ]
  }
}

resource resAzFdWaf 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2019-10-01' = {
  name: frontDoorWafName
  location: 'Global'
  properties: {
    policySettings: {
      enabledState: frontDoorWafEnabledState ? 'Enabled' : 'Disabled'
      mode: frontDoorWafMode
      customBlockResponseStatusCode: 403
    }
    customRules: {
      rules: [
        {
          name: 'blockQsExample'
          enabledState: 'Enabled'
          priority: 4
          ruleType: 'MatchRule'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 100
          matchConditions: [
              {
                  matchVariable: 'QueryString'
                  operator: 'Contains'
                  negateCondition: false
                  matchValue: [
                      'blockme'
                  ]
                  transforms: []
              }
          ]
          action: 'Block'
        }
      ]
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'DefaultRuleSet'
          ruleSetVersion: '1.0'
        }
        {
          ruleSetType: 'BotProtection'
          ruleSetVersion: 'preview-0.1'
        }
      ]
    }
  }
}

resource fdIdApimNamedValue 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: frontDoorIdNamedValue
  parent: apiManagement
  properties: {
    displayName: frontDoorIdNamedValue
    secret: true
    value: resAzFd.properties.frontdoorId
  }
}

output frontDoorName string = resAzFd.name
output frontDoorWafName string = resAzFdWaf.name
