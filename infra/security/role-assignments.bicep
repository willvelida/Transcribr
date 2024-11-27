@description('The Principal Id of the Uploader Function')
param uploaderFuncPrincipalId string

@description('The Principal Id of the File Processor Func')
param processorFuncPrincipalId string

@description('The name of the Audio File Storage Account')
param audioStorageAccountName string

@description('Name of the Uploader Func Storage Account')
param uploaderFuncStorageAccountName string

@description('Name of the Processor Func Storage Account')
param processorFuncStorageAccountName string

@description('Name of the Azure Open AI account')
param azureOpenAIAccountName string

@description('Name of the App Insights workspace')
param appInsightsName string

var openAIUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
var blobDataOwnerRoleId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'

resource openAI 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: azureOpenAIAccountName
}

resource audioStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: audioStorageAccountName
}

resource uploadFuncStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: uploaderFuncStorageAccountName
}

resource processorFuncStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: processorFuncStorageAccountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource processorAudioBlobDataOwnerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(audioStorage.id, processorFuncPrincipalId, blobDataOwnerRoleId)
  scope: audioStorage
  properties: {
    principalId: processorFuncPrincipalId
    roleDefinitionId: blobDataOwnerRoleId
    principalType: 'ServicePrincipal'
  }
}

resource processorFuncBlobDataOwnerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(processorFuncStorage.id, processorFuncPrincipalId, blobDataOwnerRoleId)
  scope: processorFuncStorage
  properties: {
    principalId: processorFuncPrincipalId
    roleDefinitionId: blobDataOwnerRoleId
    principalType: 'ServicePrincipal'
  }
}

resource processorMetricsPublisherRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appInsights.id, processorFuncPrincipalId, monitoringMetricsPublisherRoleId)
  scope: appInsights
  properties: {
    principalId: processorFuncPrincipalId
    roleDefinitionId: monitoringMetricsPublisherRoleId
    principalType: 'ServicePrincipal'
  }
}

resource processorOpenAIUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAI.id, processorFuncPrincipalId, openAIUserRoleId)
  scope: openAI
  properties: {
    principalId: processorFuncPrincipalId
    roleDefinitionId: openAIUserRoleId
    principalType: 'ServicePrincipal'
  }
}

resource uploadAudioBlobDataOwnerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(audioStorage.id, uploaderFuncPrincipalId, blobDataOwnerRoleId)
  scope: audioStorage
  properties: {
    principalId: uploaderFuncPrincipalId
    roleDefinitionId: blobDataOwnerRoleId
    principalType: 'ServicePrincipal'
  }
}

resource uploadFuncBlobDataOwnerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uploadFuncStorage.id, uploaderFuncPrincipalId, blobDataOwnerRoleId)
  scope: uploadFuncStorage
  properties: {
    principalId: uploaderFuncPrincipalId
    roleDefinitionId: blobDataOwnerRoleId
    principalType: 'ServicePrincipal'
  }
}

resource uploaderMetricsPublisherRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appInsights.id, uploaderFuncPrincipalId, monitoringMetricsPublisherRoleId)
  scope: appInsights
  properties: {
    principalId: uploaderFuncPrincipalId
    roleDefinitionId: monitoringMetricsPublisherRoleId
    principalType: 'ServicePrincipal'
  }
}
