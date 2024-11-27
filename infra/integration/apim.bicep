@description('The name of the APIM instance')
param apimName string

@description('The region where the APIM instance will be deployed')
param location string

@description('The tags that will be applied to the APIM resource')
param tags object

@description('The Integration specific tags that will be applied to Integration specific resources')
param integrationTags object = {
  ResourceType: 'Integration'
}

@description('The name of the Publisher for the APIM instance')
param publisherName string

@description('The email of the Publisher for the APIM instance')
param publisherEmail string

resource apim 'Microsoft.ApiManagement/service@2024-05-01' =   {
  name: apimName
  location: location
  tags: union(tags, integrationTags)
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
  identity: {
    type: 'SystemAssigned'
  }
}
