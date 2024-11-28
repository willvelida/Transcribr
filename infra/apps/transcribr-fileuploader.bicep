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

@description('The Name of the App Service Plan that this Function will be deployed to')
param appServicePlanName string

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

module appServicePlan '../compute/app-service-plan.bicep' = {
  name: 'upload-asp'
  params: {
    location: location
    tags: tags
    aspName: appServicePlanName
  }
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

resource flexFunctionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: funcAppName
  location: location
  tags: union(tags, computeTags)
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.outputs.appServicePlanId
    siteConfig: {
      appSettings: [
        { 
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        { 
          name: 'AudioUploadStorage__serviceUri'
          value: audioStorage.properties.primaryEndpoints.blob
        }
        { 
          name: 'APPLICATIONINSIGHTS_AUTHENTICATION_STRING'
          value: 'Authorization=AAD'
        }
        { 
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        { 
          name: 'STORAGE_ACCOUNT_CONTAINER'
          value: container.name
        }
        { 
          name: 'ERROR_RATE'
          value: '0'
        }
        {
          name: 'LATENCY_IN_SECONDS'
          value: '0'
        }
        { 
          name: 'COSMOS_DB_DATABASE_NAME'
          value: databaseName
        }
        { 
          name: 'COSMOS_DB_CONTAINER_ID'
          value: containerName
        }
        {
          name: 'COSMOS_DB__accountEndpoint'
          value: cosmosDb.properties.documentEndpoint
        }
      ]
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageAccount.properties.primaryEndpoints.blob}${container.name}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 100
        instanceMemoryMB: 2048
      }
      runtime: {
        name: 'dotnet-isolated'
        version: '8.0'
      }
    }
  }
}

@description('The Principal Id of the deployed Function App')
output principalId string = flexFunctionApp.identity.principalId

@description('The name of the Storage account that belongs to this Function')
output storageAccountName string = storageAccount.name
