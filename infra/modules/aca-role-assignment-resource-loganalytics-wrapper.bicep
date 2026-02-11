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
var resourceGroupName = resourceIdParts[4]

module logAnalyticsRoleAssignment './aca-role-assignment-resource-loganalytics.bicep' = {
  name: 'aca-rbac-la-${roleDefinitionId}'
  scope: resourceGroup(resourceGroupName)
  params: {
    logAnalyticsResourceId: logAnalyticsResourceId
    acaPrincipalId: acaPrincipalId
    roleDefinitionId: roleDefinitionId
  }
}

output roleAssignmentId string = logAnalyticsRoleAssignment.outputs.roleAssignmentId
output roleAssignmentName string = logAnalyticsRoleAssignment.outputs.roleAssignmentName
