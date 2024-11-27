@description('The name of the App Service Plan')
param aspName string

@description('The region where the App Service Plan will be deployed to')
param location string

@description('The tags that will be applied to the App Service Plan')
param tags object

@description('The compute-specific tags that will be applied to compute resources')
param computeTags object = {
  ResourceType: 'Compute'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: aspName
  location: location
  tags: union(computeTags, tags)
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

@description('The deployed App Service Plan Id')
output appServicePlanId string = appServicePlan.id
