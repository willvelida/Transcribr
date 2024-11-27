@description('The name that will be applied to the Cosmos DB account')
param accountName string

@description('The region where the Cosmos DB account will be deployed to')
param location string

@description('The generic tags that will be applied to this Cosmos DB account')
param tags object

@description('The tags that will be applied to data-specific resources')
param dataTags object = {
  ResourceType: 'Data'
}

@description('The name that will be given to the Database provisioned in this Cosmos DB account')
param databaseName string = 'TranscribrDB'

@description('The name of the container that is deployed inside the Database')
param containerName string = 'audio-transcripts'

resource account 'Microsoft.DocumentDB/databaseAccounts@2024-09-01-preview' = {
  name: accountName
  location: location
  tags: union(tags, dataTags)
  properties: {
    databaseAccountOfferType: 'Standard' 
    locations: [
      { 
        failoverPriority: 0
        locationName: location
      }
    ]

    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }

    capabilities: [
      { 
        name: 'EnableServerless'
      }
    ]
  }

  identity: {
    type: 'SystemAssigned'
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-09-01-preview' = {
  name: databaseName
  parent: account
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-09-01-preview' = {
  name: containerName
  parent: database
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          { 
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/excluded/?'
          }
        ]
      }
      uniqueKeyPolicy: {
        uniqueKeys: [
          { 
            paths: [
              '/idlong'
              '/idshort'
            ]
          }
        ]
      }
    }
  }
}
