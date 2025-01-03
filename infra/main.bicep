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

@description('The name given to the Speech Services account')
param speechServicesName string = 'speech-${appSuffix}'

@description('The name given to the Key Vault')
param keyVaultName string = 'kv-${appSuffix}'

@description('The name given to the Azure Load Testing Service')
param azureLoadTestName string = 'alt-${appSuffix}'

@description('The name given to the App Service Plan for the Upload Function')
param uploadAppServicePlanName string = 'asp-upload-${appSuffix}'

@description('The name given to the App Service Plan for the Processor Function')
param processorAppServicePlanName string = 'asp-processor-${appSuffix}'

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

var audioUploadFuncAppName = 'transcribr-upload'
var audioProcessorFuncAppName = 'transcribr-processor'

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

module speech 'ai/speech-service.bicep' = {
  name: 'speech'
  params: {
    location: location
    tags: tags
    speechServicesName: speechServicesName
    keyVaultName: keyVault.outputs.name
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

module audioUploaderFunc 'apps/transcribr-fileuploader.bicep' = {
  name: 'audio-uploader-func'
  params: {
    location: location
    tags: tags
    appInsightsName: appInsights.outputs.appInsightsName
    appServicePlanName: uploadAppServicePlanName
    audioStorageAccountName: audioStorage.outputs.storageAccountName
    containerName: cosmos.outputs.containerName
    cosmosDbAccountName: cosmos.outputs.accountName
    databaseName: cosmos.outputs.databaseName
    funcAppName: audioUploadFuncAppName
    audioStorageContainerName: audioStorage.outputs.blobContainerName
  }
}

module audioFileProcessorFunc 'apps/transcribr-fileprocessor.bicep' = {
  name: 'audio-file-processor-func'
  params: {
    location: location
    tags: tags
    appInsightsName: appInsights.outputs.appInsightsName
    appServicePlanName: processorAppServicePlanName
    audioStorageAccountName: audioStorage.outputs.storageAccountName
    azureOpenAIName: openAI.outputs.name
    chatModelName: openAI.outputs.chatModelDeploymentName
    containerName: cosmos.outputs.containerName
    cosmosDbAccountName: cosmos.outputs.accountName
    databaseName: cosmos.outputs.databaseName
    funcAppName: audioProcessorFuncAppName
    speechServiceName: speech.outputs.name
  }
}

module audioUploaderCosmosRole 'security/cosmos-role-assignment.bicep' = {
  name: 'audio-uploader-cosmos-role'
  params: {
    cosmosDbAccountName: cosmos.outputs.accountName
    principalId: audioUploaderFunc.outputs.principalId
  }
}

module audioProcessorCosmosRole 'security/cosmos-role-assignment.bicep' = {
  name: 'audio-processor-cosmos-role'
  params: {
    cosmosDbAccountName: cosmos.outputs.accountName
    principalId: audioFileProcessorFunc.outputs.principalId
  }
}

module roleAssignments 'security/role-assignments.bicep' = {
  name: 'role-assignments'
  params: {
    appInsightsName: appInsights.outputs.appInsightsName
    audioStorageAccountName: audioStorage.outputs.storageAccountName
    azureOpenAIAccountName: openAI.outputs.name
    processorFuncPrincipalId: audioFileProcessorFunc.outputs.principalId
    processorFuncStorageAccountName: audioFileProcessorFunc.outputs.storageAccountName
    uploaderFuncPrincipalId: audioUploaderFunc.outputs.principalId
    uploaderFuncStorageAccountName: audioUploaderFunc.outputs.storageAccountName
  }
}
