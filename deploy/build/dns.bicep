param aseDomainName string
param virtualNetworkId string
param aseIp string

var privateDnsZoneName = aseDomainName
var autoVmRegistration = true

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneA 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  name: '${privateDnsZoneName}/*'
  properties: {
    ttl: 3600
    aRecords: [
        {
            ipv4Address: aseIp
        }
    ]
  }
  dependsOn: [
    privateDnsZone
  ]
}

resource privateDnsZoneAscm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  name: '${privateDnsZoneName}/*.scm'
  properties: {
    ttl: 3600
    aRecords: [
        {
            ipv4Address: aseIp
        }
    ]
  }
  dependsOn: [
    privateDnsZone
  ]
}

resource privateDnsZoneAall 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  name: '${privateDnsZoneName}/@'
  properties: {
    ttl: 3600
    aRecords: [
        {
            ipv4Address: aseIp
        }
    ]
  }
  dependsOn: [
    privateDnsZone
  ]
}

resource privateDnsZoneSOA 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  name: '${privateDnsZoneName}/@'
  properties: {
    ttl: 3600
    soaRecord: {
        email: 'azureprivatedns-host.microsoft.com'
        expireTime: 2419200
        host: 'azureprivatedns.net'
        minimumTtl: 10
        refreshTime: 3600
        retryTime: 300
        serialNumber: 1
    }
  }
  dependsOn: [
    privateDnsZone
  ]
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZone.name}/${privateDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: autoVmRegistration
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}
