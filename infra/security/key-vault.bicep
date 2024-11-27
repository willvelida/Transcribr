@description('The name of the Key Vault that will be deployed')
param keyVaultName string

@description('The location that the Key Vault will be deployed to')
param location string

@description('The tags that will be applied to the Key Vault')
param tags object

@description('The security-specific tags that will be applied to security resources')
param securityTags object = {
  ResourceType: 'Security'
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: union(tags, securityTags)
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
  }
}

@description('The name of the deployed Key Vault')
output name string = keyVault.name
