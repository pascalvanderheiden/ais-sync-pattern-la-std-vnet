@minLength(3)
@maxLength(11)
param namePrefix string
param location string = resourceGroup().location
param virtualNetworkId string
param subnetName string

var aseName = '${namePrefix}-ase'
var internalLoadBalancingMode = 'Web,Publishing'
var dnsSuffix = '${aseName}.appserviceenvironment.net'
var appServicePlanName = '${aseName}-la-sp'
var numberOfWorkers = 1
var workerPool = '1v2'

resource hostingEnvironment 'Microsoft.Web/hostingEnvironments@2020-06-01' = {
  name: aseName
  location: location
  kind: 'ASEV3'
  properties: {
    name: aseName
    location: location
    ipsslAddressCount: 0
    internalLoadBalancingMode: internalLoadBalancingMode
    dnsSuffix: dnsSuffix
    virtualNetwork: {
      id: virtualNetworkId
      subnet: subnetName
    }
    workerPools: []
  }
}
resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    hostingEnvironmentProfile: {
      id: hostingEnvironment.id
    }
  }
  sku: {
    name: 'I${workerPool}'
    tier: 'IsolatedV2'
    size: 'I${workerPool}'
    family: 'Iv2'
    capacity: numberOfWorkers
  }
}

output aseName string = hostingEnvironment.name
output appServicePlanName string = serverFarm.name
