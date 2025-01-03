@description('The name given to the Azure Open AI account')
param openAIName string

@description('The location that the Azure Open AI account will be deployed to')
param location string

@description('The tags that will be applied to this Azure Open AI account')
param tags object

@description('The AI-specific tags that will be applied to AI resources')
param aiTags object = {
  ResourceType: 'AI'
}

resource azureOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIName
  location: location
  tags: union(aiTags, tags)
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }

  properties: {
    customSubDomainName: 'oai-${openAIName}'
  }
  
  identity: {
    type: 'SystemAssigned'
  }
}

resource gpt4oMiniDeploy 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: 'gpt-4o-mini'
  parent: azureOpenAI
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
    }
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
}

@description('The name of the Chat Model Deployment')
output chatModelDeploymentName string = gpt4oMiniDeploy.name

@description('The Azure Open AI name')
output name string = azureOpenAI.name
