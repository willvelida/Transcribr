@description('The name applied to the Log Analytics workspace')
param lawName string

@description('The region where the Log Analytics workspace will be deployed')
param location string

@description('The tags that will be applied to the Log Analytics workspace resource')
param tags object

@description('The tags applied to monitoring resource. Joined with main tags')
param monitorTags object = {
  ResourceType: 'Monitoring'
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawName
  location: location
  tags: union(tags, monitorTags)
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

@description('The Id of the deployed Log Analytics workspace')
output lawId string = logAnalytics.id
