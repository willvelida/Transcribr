@description('The unique suffix that will be applied to all resources')
param appSuffix string = uniqueString(resourceGroup().id)

@description('The region to deploy all resources. Default is the location of the resource group')
param location string = resourceGroup().location

@description('The tags that will be applied to all resources')
param tags object = {
  ApplicationName: 'Transcribr'
  Environment: 'Production'
  Owner: 'willvelida'
}

@description('The name given the the Log Analytics workspace')
param lawName string = 'law-${appSuffix}'

@description('The name given to the Application Insights workspace')
param appInsightsName string = 'appins-${appSuffix}'

@description('The name given to the API Management Instance')
param apimName string = 'api-${appSuffix}'

@description('The name of the Publisher')
param publisherName string

@description('The email of the Publisher')
param publisherEmail string

module logAnalytics 'monitoring/log-analytics.bicep' = {
  name: 'log-analytics'
  params: {
    location: location
    tags: tags
    lawName: lawName
  }
}

module appInsights 'monitoring/app-insights.bicep' = {
  name: 'app-insights'
  params: {
    location: location
    tags: tags
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceId: logAnalytics.outputs.lawId
  }
}

module apim 'integration/apim.bicep' = {
  name: 'apim'
  params: {
    location: location 
    tags: tags
    apimName: apimName
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}
