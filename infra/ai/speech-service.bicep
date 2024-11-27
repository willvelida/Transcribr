@description('The name given to the Speech Services account')
param speechServicesName string

@description('The location that the Speech Services account will be deployed to')
param location string

@description('The tags that will be applied to this Speech Services account')
param tags object

@description('The AI-specific tags that will be applied to AI resources')
param aiTags object = {
  ResourceType: 'AI'
}

resource speechServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: speechServicesName
  location: location
  tags: union(aiTags, tags)
  kind: 'SpeechServices'
  sku: {
    name: 'S0'
  }
  properties: {}
  identity: {
    type: 'SystemAssigned'
  }
}
