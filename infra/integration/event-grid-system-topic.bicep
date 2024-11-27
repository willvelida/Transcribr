@description('The name of the system topic')
param systemTopicName string

@description('The region that this System Topic will be deployed to')
param location string

@description('The tags that will be applied to this System Topic')
param tags object

@description('The storage account id for the system topic')
param storageAccountId string

@description('The Integration specific tags that will be applied to Integration specific resources')
param integrationTags object = {
  ResourceType: 'Integration'
}

resource systemTopic 'Microsoft.EventGrid/systemTopics@2024-06-01-preview' = {
  name: systemTopicName
  location: location
  tags: union(tags, integrationTags)
  properties: {
    source: storageAccountId
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}
