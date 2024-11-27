@description('The unique suffix that will be applied to all resources')
param appSuffix string = uniqueString(resourceGroup().id)

@description('The region to deploy all resources. Default is the location of the resource group')
param location string = resourceGroup().location

@description('The tags that will be applied to all resources')
param tags object = {
  ApplicationName: 'Transcribr'
  Environment: 'Production'
  Owner: 'willvelida'
}

@description('The name given the the Log Analytics workspace')
param lawName string = 'law-${appSuffix}'

@description('The name given to the Application Insights workspace')
param appInsightsName string = 'appins-${appSuffix}'

@description('The name given to the API Management Instance')
param apimName string = 'api-${appSuffix}'

@description('The name given to the Cosmos DB account')
param cosmosDbName string = 'cosmos-${appSuffix}'

@description('The name given to the Azure Open AI account')
param azureOpenAIName string = 'oai-${appSuffix}'

@description('The name given to the Key Vault')
param keyVaultName string = 'kv-${appSuffix}'

@description('The name given to the Azure Load Testing Service')
param azureLoadTestName string = 'alt-${appSuffix}'

@description('The name given to the Event Grid System Topic')
param eventGridSystemTopicName string = 'evgt-audio-${appSuffix}'

@description('The name of the Storage Account that files will be uploaded to')
param audioStorageAccount string = 'stor${replace(appSuffix, '-', '')}'

@description('The name of the container inside the audio files storage account')
param audioStorageContainer string = 'audios'

@description('The name of the Publisher')
param publisherName string

@description('The email of the Publisher')
param publisherEmail string

module logAnalytics 'monitoring/log-analytics.bicep' = {
  name: 'log-analytics'
  params: {
    location: location
    tags: tags
    lawName: lawName
  }
}

module appInsights 'monitoring/app-insights.bicep' = {
  name: 'app-insights'
  params: {
    location: location
    tags: tags
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceId: logAnalytics.outputs.lawId
  }
}

module apim 'integration/apim.bicep' = {
  name: 'apim'
  params: {
    location: location 
    tags: tags
    apimName: apimName
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

module cosmos 'data/cosmos-db.bicep' = {
  name: 'cosmos'
  params: {
    location: location
    tags: tags
    accountName: cosmosDbName 
  }
}

module openAI 'ai/azure-open-ai.bicep' = {
  name: 'open-ai'
  params: {
    location: location
    tags: tags
    openAIName: azureOpenAIName 
  }
}

module keyVault 'security/key-vault.bicep' = {
  name: 'key-vault'
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
  }
}

module loadTest 'integration/azure-load-testing.bicep' = {
  name: 'load-test'
  params: {
    location: location
    tags: tags
    loadTestName: azureLoadTestName
  }
}

module systemTopic 'integration/event-grid-system-topic.bicep' = {
  name: 'system-topic'
  params: {
    location: location
    tags: tags
    systemTopicName: eventGridSystemTopicName
    storageAccountId: audioStorage.outputs.storageAccountId
  }
}

module audioStorage 'data/storage-account.bicep' = {
  name: 'audio-storage'
  params: {
    location: location
    tags: tags
    containerName: audioStorageContainer
    storageAccountName: audioStorageAccount
  }
}
