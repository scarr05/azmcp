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
var resourceGroupName = resourceIdParts[4]

module kustoRoleAssignment './aca-role-assignment-resource-kusto.bicep' = {
  name: 'aca-role-assignment-kusto-${roleDefinitionId}'
  scope: resourceGroup(resourceGroupName)
  params: {
    kustoResourceId: kustoResourceId
    acaPrincipalId: acaPrincipalId
    roleDefinitionId: roleDefinitionId
  }
}

output roleAssignmentId string = kustoRoleAssignment.outputs.roleAssignmentId
output roleAssignmentName string = kustoRoleAssignment.outputs.roleAssignmentName
