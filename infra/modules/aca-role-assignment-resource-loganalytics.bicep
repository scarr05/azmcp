@description('Full resource ID of the Log Analytics workspace')
@metadata({
  example: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.OperationalInsights/workspaces/myworkspace'
})
param logAnalyticsResourceId string

@description('Azure Container App Managed Identity principal/object ID (GUID)')
param acaPrincipalId string

@description('Azure RBAC role definition ID (GUID) to grant the Container App managed identity on the Log Analytics workspace')
param roleDefinitionId string

// Expected format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}
var resourceIdParts = split(logAnalyticsResourceId, '/')
var workspaceName = resourceIdParts[8]

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspaceName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, acaPrincipalId, roleDefinitionId)
  scope: logAnalyticsWorkspace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: acaPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
output roleAssignmentName string = roleAssignment.name
