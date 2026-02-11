@description('Location for all resources')
param location string = resourceGroup().location

@description('Name for the Azure Container App')
param acaName string

@description('Display name for the Entra App')
param entraAppDisplayName string

@description('Microsoft Foundry project resource ID for assigning Entra App role to Foundry project managed identity')
param foundryProjectResourceId string

@description('Application Insights connection string. Use "DISABLED" to disable telemetry, or provide existing connection string. If omitted, new App Insights will be created.')
param appInsightsConnectionString string = ''

// --- Optional resource IDs: provide only the ones matching your chosen namespaces ---

@description('Full resource ID of the Storage Account (required when using storage namespace)')
param storageResourceId string = ''

@description('Full resource ID of the Azure Data Explorer cluster (required when using kusto namespace)')
param kustoResourceId string = ''

@description('Full resource ID of the Log Analytics workspace (required when using monitor namespace, e.g. for Sentinel)')
param logAnalyticsResourceId string = ''

// --- Namespace configuration ---
// Derived from which resource IDs are provided. Each non-empty resource ID enables its namespace.
var enableStorage = !empty(storageResourceId)
var enableKusto = !empty(kustoResourceId)
var enableMonitor = !empty(logAnalyticsResourceId)

var namespaces = union(
  enableStorage ? ['storage'] : [],
  enableKusto ? ['kusto'] : [],
  enableMonitor ? ['monitor'] : []
)

// Deploy Application Insights if appInsightsConnectionString is empty and not DISABLED
var appInsightsName = '${acaName}-insights'
//
module appInsights 'modules/application-insights.bicep' = {
  name: 'application-insights-deployment'
  params: {
    appInsightsConnectionString: appInsightsConnectionString
    name: appInsightsName
    location: location
  }
}

// Deploy Entra App
var entraAppUniqueName = '${replace(toLower(entraAppDisplayName), ' ', '-')}-${uniqueString(resourceGroup().id)}'
//
module entraApp 'modules/entra-app.bicep' = {
  name: 'entra-app-deployment'
  params: {
    entraAppDisplayName: entraAppDisplayName
    entraAppUniqueName: entraAppUniqueName
  }
}

// Deploy ACA Infrastructure to host Azure MCP Server
module acaInfrastructure 'modules/aca-infrastructure.bicep' = {
  name: 'aca-infrastructure-deployment'
  params: {
    name: acaName
    location: location
    appInsightsConnectionString: appInsights.outputs.connectionString
    azureMcpCollectTelemetry: string(!empty(appInsights.outputs.connectionString))
    azureAdTenantId: tenant().tenantId
    azureAdClientId: entraApp.outputs.entraAppClientId
    namespaces: namespaces
  }
}

// ============================================================================
// RBAC Role Assignments — conditional based on enabled namespaces
// ============================================================================

// --- Storage RBAC (when storage namespace is enabled) ---
var storageBlobDataReaderRoleId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

module acaStorageBlobRoleAssignment './modules/aca-role-assignment-resource.bicep' = if (enableStorage) {
  name: 'aca-storage-blob-role-assignment'
  params: {
    storageResourceId: storageResourceId
    acaPrincipalId: acaInfrastructure.outputs.containerAppPrincipalId
    roleDefinitionId: storageBlobDataReaderRoleId
  }
}

module acaStorageAccountRoleAssignment './modules/aca-role-assignment-resource.bicep' = if (enableStorage) {
  name: 'aca-storage-account-role-assignment'
  params: {
    storageResourceId: storageResourceId
    acaPrincipalId: acaInfrastructure.outputs.containerAppPrincipalId
    roleDefinitionId: readerRoleId
  }
}

// --- Kusto / Azure Data Explorer RBAC (when kusto namespace is enabled) ---
// Database Viewer: allows .show databases, .show tables, and query execution
var kustoAllDatabasesViewerRoleId = '2ec9d3d3-7cd2-4529-b497-2a2c1768c4ce'

module acaKustoViewerRoleAssignment './modules/aca-role-assignment-resource-kusto-wrapper.bicep' = if (enableKusto) {
  name: 'aca-kusto-viewer-role-assignment'
  params: {
    kustoResourceId: kustoResourceId
    acaPrincipalId: acaInfrastructure.outputs.containerAppPrincipalId
    roleDefinitionId: kustoAllDatabasesViewerRoleId
  }
}

module acaKustoReaderRoleAssignment './modules/aca-role-assignment-resource-kusto-wrapper.bicep' = if (enableKusto) {
  name: 'aca-kusto-reader-role-assignment'
  params: {
    kustoResourceId: kustoResourceId
    acaPrincipalId: acaInfrastructure.outputs.containerAppPrincipalId
    roleDefinitionId: readerRoleId
  }
}

// --- Monitor / Log Analytics RBAC (when monitor namespace is enabled, e.g. for Sentinel) ---
// Log Analytics Reader: read-only access to Log Analytics workspace data including Sentinel tables
var logAnalyticsReaderRoleId = '73c42c96-874c-492b-b04d-ab87d138a893'

module acaLogAnalyticsReaderRoleAssignment './modules/aca-role-assignment-resource-loganalytics-wrapper.bicep' = if (enableMonitor) {
  name: 'aca-loganalytics-reader-role-assignment'
  params: {
    logAnalyticsResourceId: logAnalyticsResourceId
    acaPrincipalId: acaInfrastructure.outputs.containerAppPrincipalId
    roleDefinitionId: logAnalyticsReaderRoleId
  }
}

module acaLogAnalyticsResourceReaderRoleAssignment './modules/aca-role-assignment-resource-loganalytics-wrapper.bicep' = if (enableMonitor) {
  name: 'aca-loganalytics-resource-reader-role-assignment'
  params: {
    logAnalyticsResourceId: logAnalyticsResourceId
    acaPrincipalId: acaInfrastructure.outputs.containerAppPrincipalId
    roleDefinitionId: readerRoleId
  }
}

// ============================================================================
// Foundry role assignment
// ============================================================================
module foundryRoleAssignment './modules/foundry-role-assignment-entraapp.bicep' = {
  name: 'foundry-role-assignment'
  params: {
    foundryProjectResourceId: foundryProjectResourceId
    entraAppServicePrincipalObjectId: entraApp.outputs.entraAppServicePrincipalObjectId
    entraAppRoleId: entraApp.outputs.entraAppRoleId
  }
}

// ============================================================================
// Outputs
// ============================================================================

// Outputs for azd and other consumers
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_RESOURCE_GROUP string = resourceGroup().name
output AZURE_LOCATION string = location

// Entra App outputs
output ENTRA_APP_CLIENT_ID string = entraApp.outputs.entraAppClientId
output ENTRA_APP_OBJECT_ID string = entraApp.outputs.entraAppObjectId
output ENTRA_APP_SERVICE_PRINCIPAL_ID string = entraApp.outputs.entraAppServicePrincipalObjectId
output ENTRA_APP_ROLE_ID string = entraApp.outputs.entraAppRoleId
output ENTRA_APP_IDENTIFIER_URI string = entraApp.outputs.entraAppIdentifierUri

// ACA Infrastructure outputs
output CONTAINER_APP_URL string = acaInfrastructure.outputs.containerAppUrl
output CONTAINER_APP_NAME string = acaInfrastructure.outputs.containerAppName
output CONTAINER_APP_PRINCIPAL_ID string = acaInfrastructure.outputs.containerAppPrincipalId
output AZURE_CONTAINER_APP_ENVIRONMENT_ID string = acaInfrastructure.outputs.containerAppEnvironmentId

// Enabled namespaces output
output ENABLED_NAMESPACES array = namespaces

// Application Insights outputs
output APPLICATION_INSIGHTS_NAME string = appInsightsName
output APPLICATION_INSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AZURE_MCP_COLLECT_TELEMETRY string = string(!empty(appInsights.outputs.connectionString))
