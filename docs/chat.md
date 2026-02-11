mcp/servers/Azure.Mcp.Server at main · microsoft/mcpcan you provide me a step by step on confiruging the Azure MCP server for use within foundary projects in my Azure subscripiton

``` thinking
13:30Thinking about configuring Azure MCP server integration with Foundry projectsThe user wants a step-by-step guide on configuring the Azure MCP server from the Microsoft GitHub repo for use within Foundry projects in their Azure subscription. Let me fetch the repo to get the actual documentation.DoneLet me grab the details from that repo first.Synthesized information to construct comprehensive configuration guideFailed to fetch https://github.com/microsoft/mcp/tree/main/mcp/servers/Azure.Mcp.ServerLet me search for the repo instead.microsoft mcp Azure.Mcp.Server github configuration10 resultsGitHub - Azure/azure-mcp: The Azure MCP Server, bringing the power of Azure to your agents.github.comGitHub - microsoft/azure-devops-mcp: The MCP server for Azure DevOps, bringing the power of Azure DevOps directly to your agents.github.comMCP Registry | Azure MCP Server · GitHubgithub.commcp/servers/Azure.Mcp.Server at main · microsoft/mcpgithub.comGet started with the Azure MCP Server - Azure MCP Server | Microsoft Learnlearn.microsoft.comConnect GitHub Copilot coding agent to the Azure MCP Server - Azure MCP Server | Microsoft Learnlearn.microsoft.comAzure MCP Server documentation - Azure MCP Server | Microsoft Learnlearn.microsoft.comGitHub - Tiberriver256/mcp-server-azure-devops: An MCP server for Azure DevOpsgithub.comMCP Registry | Azure DevOps · GitHubgithub.comGitHub - microsoft/mcp: Catalog of official Microsoft MCP (Model Context Protocol) server implementations for AI-powered data access and tool integrationgithub.comThe key info is that Microsoft Foundry and Copilot Studio require remote MCP server endpoints, and to self-host the Azure MCP Server for these platforms, you deploy it as a remote MCP server on Azure Container Apps using azd templates. Let me get the specific details from the official docs and the remote hosting templates.Azure MCP Server remote hosting Azure Container Apps Foundry azd template10 resultsDeploy the Azure MCP Server as a remote MCP server and connect using Microsoft Foundry - Azure MCP Server | Microsoft Learnlearn.microsoft.comGitHub - Azure-Samples/azmcp-foundry-aca-migithub.comDeploy the Azure MCP Server as a remote MCP server and connect using Copilot Studio - Azure MCP Server | Microsoft Learnlearn.microsoft.comHost Remote MCP Servers in Azure App Service | Microsoft Community Hubtechcommunity.microsoft.comConnect to a Model Context Protocol Server Endpoint in Foundry Agent Service (Preview) - Microsoft Foundry | Microsoft Learnlearn.microsoft.comGitHub - Azure-Samples/foundry-agent-service-remote-mcp-python: This is a quickstart template to easily build and deploy a custom remote MCP server to the cloud using Azure Functions with Python, and then load the MCP tools in Foundry Agent Servicegithub.comBuild and register a Model Context Protocol (MCP) server - Microsoft Foundry | Microsoft Learnlearn.microsoft.comGitHub - powergentic/azd-mcp-csharp: An AZD template to deploy a Model Context Protocol (MCP) server written in C# to Azure Container Apps using SSE Transport.github.comRemote MCP with Azure Container Apps (Node.js/TypeScript/JavaScript) - Code Samples | Microsoft Learnlearn.microsoft.comDeploying MCP Server Using Azure Container Apps | Microsoft Community Hubtechcommunity.microsoft.comNow I have comprehensive information about deploying the Azure MCP Server for use with Microsoft Foundry projects. Let me also fetch the detailed MS Learn article for the Foundry-specific deployment to get the exact steps.Deploy the Azure MCP Server as a remote MCP server and connect using Microsoft Foundry - Azure MCP Serverlearn.microsoft.comNow I have the full picture. Let me write up a clear step-by-step guide.Done
```

Right, Sam — here's the end-to-end walkthrough. The key thing to understand is that Foundry Agent Service only accepts remote MCP server endpoints GitHubMicrosoft Learn, so you need to self-host the Azure MCP Server on Azure Container Apps first, then wire it into your Foundry project.

Prerequisites
Before you start, make sure you have:

An Azure subscription with Owner or User Access Administrator access.
Azure Developer CLI (azd) installed — if not, grab it from the install docs.
An Azure Storage account (or whichever resource you want the MCP server to manage — the reference template uses storage as the example namespace).
A Microsoft Foundry project already created at ai.azure.com. You'll need its Azure resource ID.
Know which Azure MCP Server tool namespaces you want to enable. The full list is in azmcp-commands.md on the repo. The reference template ships with the storage namespace.


Step 1: Deploy the Azure MCP Server to Azure Container Apps
Clone and initialise the azmcp-foundry-aca-mi azd template: Microsoft Learn
bashazd init -t azmcp-foundry-aca-mi
You'll be prompted for an environment name — pick something meaningful like azmcp-foundry-prod.
Then deploy everything:
bashazd up
azd will prompt you for four things: Microsoft Learn

Subscription — select the target subscription.
Project resource ID — the full Azure resource ID of your Microsoft Foundry project (you can grab this from the portal under the project's Properties blade).
Storage Account resource ID — the resource ID of the storage account you want the MCP server to access.
Resource group — create or select one.

Step 2: Note the deployment outputs
Once deployment completes, retrieve the environment values: Microsoft Learn
bashazd env get-values
```

You'll get output like:
```
CONTAINER_APP_URL="https://azure-mcp-storage-server.<name>.eastus2.azurecontainerapps.io"
ENTRA_APP_CLIENT_ID="<your-app-client-id>"
Keep both of those handy — you need them in the next step.
Step 3: What azd just provisioned for you
It's worth understanding what's been deployed, because this is all Bicep under the hood and you may want to customise it:

Azure Container App running the Azure MCP Server with the storage namespace enabled. Microsoft Learn
Entra ID role assignments — the Container App's managed identity gets Reader and Storage Blob Data Reader on the target storage account. Microsoft Learn
Entra app registration — provides OAuth 2.0 authentication with an Mcp.Tools.ReadWrite.All role, assigned to the Foundry project's managed identity. Microsoft Learn
Application Insights for telemetry and monitoring. Microsoft Learn

Step 4: Connect the MCP Server to your Foundry Agent
Navigate to your Foundry project at https://ai.azure.com/nextgen, then: Microsoft Learn

Go to Build → Create agent (or open an existing agent).
In the Tools section, click + Add.
Select the Custom tab.
Choose Model Context Protocol, then click Create.
Fill in the connection details:

Name — give it a descriptive label (e.g. "Azure Storage MCP").
Remote MCP Server — paste in the CONTAINER_APP_URL from Step 2.
Authentication — select Microsoft Entra → Project Managed Identity.
Type — Project Managed Identity.
Audience — paste in the ENTRA_APP_CLIENT_ID from Step 2.


Click Connect.

That's it — the agent is now wired up and can use Azure MCP Server tools to perform Azure operations on your behalf. Microsoft Learn
Step 5: Test it
In the Foundry agent playground, try prompts like "List my Azure Storage containers" or "Show me the blobs in container X". The agent will invoke the MCP tools behind the scenes.
Cleanup
When you're done (or if this was a proof of concept):
bashazd down

Extending beyond storage
The reference template only enables the storage namespace, but the Azure MCP Server supports many more — compute, networking, databases, etc. To add more namespaces you'd modify the Container App's startup configuration in the Bicep template (specifically the command/args for the container) to include additional namespaces, then redeploy with azd deploy. You'll also need to add appropriate RBAC role assignments for whatever resources those new namespaces need to access.
The full command reference is at that azmcp-commands.md link — worth a browse to see what's available. Given your MSP work, the compute and monitor namespaces would probably be immediately useful for customer environments.I want to use the data explorer mcp name space what resource ID would i provide in step 119:39Identified Azure Data Explorer cluster resource ID format neededThe user wants to use the "data explorer" namespace specifically. Let me search for more details about the Azure MCP Server's data explorer namespace and what Azure resources it interacts with — this would likely be Azure Data Explorer (ADX/Kusto) clusters.Azure MCP Server data explorer namespace azmcp commands Kusto10 resultsazure-mcp/docs/azmcp-commands.md at main · Azure/azure-mcpgithub.commcp/servers/Azure.Mcp.Server/docs/azmcp-commands.md at main · microsoft/mcpgithub.comAzure Data Explorer - Azure MCP Server | Microsoft Learnlearn.microsoft.comGitHub - ZZZHDW/mcp-server-kusto: A mcp server that uses azure data explorer as a backendgithub.comAzure Data Explorer with Kusto Tools - Azure MCP Serverlearn.microsoft.comKusto MCP Server | Awesome MCP Serversmcpservers.orgMCP Kusto Server - playbooksplaybooks.comKusto (Azure Data Explorer) MCP server for AI agentsplaybooks.comUse the Model Context Protocol (MCP) Server With ADX Clusters - Azure Data Explorer | Microsoft Learnlearn.microsoft.comGitHub - abhirockzz/mcp_kusto: Vibe querying with MCP server for Azure Data Explorer (Kusto)github.comThe user wants to use the kusto (Azure Data Explorer) namespace with the Azure MCP Server in Foundry. The reference template (azmcp-foundry-aca-mi) is built around the storage namespace and asks for a Storage Account resource ID. If Sam wants to use the kusto namespace instead, he'd need to provide the resource ID of his Azure Data Explorer (ADX) cluster.
Looking at the commands, the kusto tools accept either a --cluster-uri or --subscription + --cluster combo. The resource ID the managed identity needs RBAC on would be the ADX cluster resource ID.
The resource ID format would be:
/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Kusto/clusters/{cluster-name}
He'd also need to modify the template to use the kusto namespace instead of storage, and adjust the RBAC role assignments accordingly.Show moreDoneGood question — the reference azd template is hardcoded around the storage namespace, so switching to kusto (Data Explorer) requires a bit of template surgery. Here's what you need to know:
The Resource ID you'd provide
You'd provide the resource ID of your Azure Data Explorer cluster, which follows this format:
/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Kusto/clusters/{cluster-name}
You can grab this from the portal (ADX cluster → Properties → Resource ID) or via CLI:
bashaz kusto cluster show --name <cluster-name> --resource-group <rg-name> --query id -o tsv
What you'd need to change in the template
The azmcp-foundry-aca-mi template won't work out of the box for the kusto namespace — it's wired for storage. You'd need to modify a few things:

Container App startup args — change the namespace from storage to kusto in the Bicep that configures the container command.
RBAC role assignments — the template's aca-role-assignment-resource-storage.bicep assigns Reader and Storage Blob Data Reader to the Container App's managed identity on the storage account. For ADX, you'd replace those with roles on your ADX cluster instead. The identity needs permissions for .show databases, .show table, .show tables, and query execution on the database. GitHub In practice, this means assigning the Database Viewer role (or Database Admin if you want write operations) at the ADX database level, plus Reader at the cluster level.
azd input parameters — swap the "Storage Account resource ID" prompt for an "ADX Cluster resource ID" prompt in the template's config.

Practical approach
Rather than fighting the template, you could:

Clone the template: azd init -t azmcp-foundry-aca-mi
Edit main.bicep to change the namespace parameter from storage to kusto
Replace the storage RBAC Bicep module with one that assigns appropriate Kusto roles on your ADX cluster
Run azd up, providing your Foundry project resource ID and ADX cluster resource ID when prompted

The kusto tools accept either a --cluster-uri directly or a --subscription + --cluster combination GitHub, so the MCP server will resolve the cluster from those parameters at runtime — but the managed identity still needs the right RBAC to actually talk to it.
Want me to sketch out the modified Bicep for the role assignments?