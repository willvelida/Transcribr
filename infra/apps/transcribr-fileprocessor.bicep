@description('The name of the Function App')
param funcAppName string

@description('The region where the Function App will be deployed')
param location string

@description('The Tags that will be applied to the Function App')
param tags object

@description('The compute-specific tags that will be applied to compute resources')
param computeTags object = {
  ResourceType: 'Transcribr.FileProcessor'
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

@description('The Azure Open AI instance that this Function App will use')
param azureOpenAIName string

@description('The chat model that this Function App will use')
param chatModelName string

@description('The Speech Service that this Function App will use')
param speechServiceName string

var blobDataOwnerRoleId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'
var openAIUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

resource audioStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: audioStorageAccountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-08-15' existing = {
  name: cosmosDbAccountName
}

resource azureOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: azureOpenAIName
}

resource speechService 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: speechServiceName
}

module appServicePlan '../compute/app-service-plan.bicep' = {
  name: 'processor-asp'
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

resource flexFunctionApp 'Microsoft.Web/sites@2024-04-01' = {
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
          name: 'STORAGE_ACCOUNT_URL'
          value: audioStorage.properties.primaryEndpoints.blob
        }
        { 
          name: 'STORAGE_ACCOUNT_EVENT_GRID__blobServiceUri'
          value: audioStorage.properties.primaryEndpoints.blob
        }
        { 
          name: 'STORAGE_ACCOUNT_EVENT_GRID__queueServiceUri'
          value: audioStorage.properties.primaryEndpoints.queue
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
        { 
          name: 'AZURE_OPENAI_ENDPOINT'
          value: azureOpenAI.properties.endpoint
        }
        { 
          name: 'CHAT_MODEL_DEPLOYMENT_NAME'
          value: chatModelName
        }
        {
          name: 'SPEECH_TO_TEXT_ENDPOINT'
          value: speechService.properties.endpoint
        }
        {
          name: 'SPEECH_TO_TEXT_API_KEY'
          value: speechService.listKeys().key1
        }
      ]
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: storageContainerName
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

resource audioBlobDataOwnerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(audioStorage.id, flexFunctionApp.id, blobDataOwnerRoleId)
  scope: audioStorage
  properties: {
    principalId: flexFunctionApp.identity.principalId
    roleDefinitionId: blobDataOwnerRoleId
    principalType: 'ServicePrincipal'
  }
}

resource funcBlobDataOwnerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, flexFunctionApp.id, blobDataOwnerRoleId)
  scope: storageAccount
  properties: {
    principalId: flexFunctionApp.identity.principalId
    roleDefinitionId: blobDataOwnerRoleId
    principalType: 'ServicePrincipal'
  }
}

resource metricsPublisherRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appInsights.id, flexFunctionApp.id, monitoringMetricsPublisherRoleId)
  scope: appInsights
  properties: {
    principalId: flexFunctionApp.identity.principalId
    roleDefinitionId: monitoringMetricsPublisherRoleId
    principalType: 'ServicePrincipal'
  }
}

resource openAIUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(azureOpenAI.id, flexFunctionApp.id, openAIUserRoleId)
  scope: azureOpenAI
  properties: {
    principalId: flexFunctionApp.identity.principalId
    roleDefinitionId: openAIUserRoleId
    principalType: 'ServicePrincipal'
  }
}

@description('The Principal Id of the deployed Function App')
output principalId string = flexFunctionApp.identity.principalId
