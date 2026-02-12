targetScope = 'subscription'

@description('Azure Container App Managed Identity principal/object ID (GUID)')
param acaPrincipalId string

@description('Azure RBAC role definition ID (GUID) to grant at subscription level')
param roleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, acaPrincipalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: acaPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
output roleAssignmentName string = roleAssignment.name
