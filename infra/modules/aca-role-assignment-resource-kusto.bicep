@description('Full resource ID of the Azure Data Explorer cluster')
@metadata({
  example: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Kusto/clusters/mycluster'
})
param kustoResourceId string

@description('Azure Container App Managed Identity principal/object ID (GUID)')
param acaPrincipalId string

@description('Azure RBAC role definition ID (GUID) to grant the Container App managed identity on the ADX cluster')
param roleDefinitionId string

// Expected format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Kusto/clusters/{clusterName}
var resourceIdParts = split(kustoResourceId, '/')
var clusterName = resourceIdParts[8]

resource kustoCluster 'Microsoft.Kusto/clusters@2023-08-15' existing = {
  name: clusterName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kustoCluster.id, acaPrincipalId, roleDefinitionId)
  scope: kustoCluster
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: acaPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
output roleAssignmentName string = roleAssignment.name
