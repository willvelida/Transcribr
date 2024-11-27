@description('The name given to the Load Testing service')
param loadTestName string

@description('The region that the Load Testing Service will be deployed to')
param location string

@description('The tags that will be applied to the Load Testing Service')
param tags object

@description('The Integration specific tags that will be applied to Integration specific resources')
param integrationTags object = {
  ResourceType: 'Integration'
}

resource azureLoadTest 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: loadTestName
  location: location
  tags: union(integrationTags, tags)
  identity: {
    type: 'SystemAssigned'
  }
}
