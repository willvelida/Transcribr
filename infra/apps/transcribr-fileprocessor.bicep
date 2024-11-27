@description('The name of the Function App')
param funcAppName string

@description('The region where the Function App will be deployed')
param location string

@description('The Tags that will be applied to the Function App')
param tags object

@description('The compute-specific tags that will be applied to compute resources')
param computeTags object = {
  ResourceType: 'Transcribr.FileUploader'
}

@description('The Id of the App Service Plan that this Function will be deployed to')
param appServicePlanId string

@description('The Storage Account that belongs to this Function App')
param storageAccountName string = 'stor${replace(funcAppName, '-', '')}'

@description('The Storage Configuration that this Function App uses for Deployment')
param storageContainerName string = 'deploymentpackage'

@description('The name of the Audio Storage Account')
param audioStorageAccountName string

@description('The Application Insights instance that this Function App will send logs to')
param appInsightsName string

@description('The name of the Cosmos DB account that this Function App will use')
param cosmosDbAccountName string

@description('The name of the Cosmos DB Database that this Function App will use')
param databaseName string

@description('The name of the Cosmos DB container that this Function App will use')
param containerName string

resource audioStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: audioStorageAccountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-08-15' existing = {
  name: cosmosDbAccountName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: union(tags, computeTags)
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: storageContainerName
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}
