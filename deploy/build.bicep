// Params can be injected during deployment, typically for deploy-time values
param resource_group string
param apim_name string
param apim_company string
param storage_name string
param appinsights_name string

var location = 'westeurope'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resource_group 
  location: location
}

// consume the below module declaration in this file, and deploy it to the newly-created rg
module myMod 'rgcontents' = {
  name: 'myModule'
  scope: resourceGroup(rg.name)
  params: {
    myTags: {
      a: 'b'
    }
  }
}

// declare the module in the same file
moduledecl 'rgcontents' = {
  targetScope = 'resourceGroup'

  param myTags object = {}

  resource xyz 'My.Rp/a@2020-01-01' = {
    name: 'xyz'
    tags: myTags
    ...
  }
}

resource sa 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storage_name
  location: location
  kind: 'StorageV2'
  sku:{
    name: 'Standard_LRS'
  }
}

// Link container to storage account by providing path as name
resource saContainerApim 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${sa.name}/default/apim-files'
}
resource saContainerApi 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${sa.name}/default/api-files'
}

resource apim 'Microsoft.ApiManagement/service@2019-12-01' = {
  name: apim_name
  location: location
  sku:{
    capacity: 1
    name: 'Developer'	
  }
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    publisherName: apim_company
    publisherEmail: 'email@${apim_company}.com'
  }
}

resource apimPolicy 'Microsoft.ApiManagement/service/policies@2019-12-01' = {
  name: '${apim.name}/policy'
  properties:{
    format: 'rawxml'
    value: '<policies><inbound /><backend><forward-request /></backend><outbound /><on-error /></policies>'
  }
}

// Create Application Insights
resource ai 'Microsoft.Insights/components@2015-05-01' = {
  name: appinsights_name
  location: location
  kind: 'web'
  properties:{
    Application_Type:'web'
  }
}

// Create Logger and link logger
resource apimLogger 'Microsoft.ApiManagement/service/loggers@2019-12-01' = {
  name: '${apim.name}/${apim.name}-logger'
  properties:{
    resourceId: '${ai.id}'
    loggerType: 'applicationInsights'
    credentials:{
      instrumentationKey: '${ai.properties.InstrumentationKey}'
    }
  }
}
