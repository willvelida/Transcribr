@description('The name given to the Speech Services account')
param speechServicesName string

@description('The location that the Speech Services account will be deployed to')
param location string

@description('The tags that will be applied to this Speech Services account')
param tags object

@description('The name of the Key Vault that the API key will be stored in')
param keyVaultName string

@description('The AI-specific tags that will be applied to AI resources')
param aiTags object = {
  ResourceType: 'AI'
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
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

resource apiSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'speechToTextApiKey'
  parent: keyVault
  properties: {
    value: speechServices.listKeys().key1
  }
}

@description('The name of the deployed Speech Services Account')
output name string = speechServices.name
