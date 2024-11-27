@description('The name of the storage account')
param storageAccountName string

@description('The name of the Blob Container that will be created as part of this Storage account')
param containerName string

@description('The region that the storage account will be deployed to')
param location string

@description('The tags that will be applied to the storage account')
param tags object

@description('The tags that will be applied to data-specific resources')
param dataTags object = {
  ResourceType: 'Data'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: union(tags, dataTags)
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
  name: containerName
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}
