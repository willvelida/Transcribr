@description('The name applied to the Application Insights workspace')
param appInsightsName string

@description('The region where the Application Insights workspace will be deployed to')
param location string

@description('The tags that will be applied to the Application Insights workspace resource')
param tags object

@description('The tags applied to monitoring resource. Joined with main tags')
param monitorTags object = {
  ResourceType: 'Monitoring'
}

@description('The Log Analytics Workspace Id that this Application Insights workspace will be connected to')
param logAnalyticsWorkspaceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: union(tags, monitorTags)
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    DisableLocalAuth: true
  }
}

@description('The name of the deployed Application Insights workspace')
output appInsightsName string = appInsights.name
