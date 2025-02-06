# Azure Bicep Deployment

This deployment template is designed to deploy various Azure resources for an enterprise-scale environment. It includes modules to create resource groups, load balancers, Azure Front Door, Web Application Firewall (WAF) policies, private link services, and Log Analytics workspaces, based on the provided parameters.

## Parameters

- **updatedBy**: Name of the person updating the environment.
- **environmentType**: Specifies the environment type (`test`, `dev`, `prod`, `acc`, `poc`).
- **subscriptionId**: The subscription ID where the resources are deployed.
- **deploymentGuid**: Unique identifier for the deployment (defaults to `newGuid()`).
- **productType**: Type of product being deployed (`frontdoor`).
- **location**: The Azure region to deploy the resources (default is `westeurope`).
- **locationShortCode**: Location shortcode for use in naming conventions.
- **tags**: Tags for the resources (Environment, LastUpdatedOn, LastDeployedBy).
- **resourceGroupName**: Name of the resource group.
- **azureFrontDoorName**: Name of the Azure Front Door resource.
- **azureFrontDoorSKU**: SKU for the Azure Front Door.
- **azureFrontDoorLocation**: Location of the Azure Front Door resource.
- **azureFrontDoorAFDEndpointName**: Name of the AFD endpoint.
- **hostDomainName**: Host domain for the custom domain.
- **customDomainName**: Custom domain name for the Azure Front Door.
- **originGroupName**: Name of the origin group in Azure Front Door.
- **originName**: Name of the origin in the origin group.
- **routeName**: Name of the route for the Azure Front Door.
- **privateLinkServiceName**: Name of the private link service.
- **loadBalancerName**: Name of the load balancer.
- **frontendIPConfigurationName**: Name of the frontend IP configuration for the load balancer.
- **backendAddressPoolName**: Name of the backend address pool for the load balancer.
- **loadBalancerRuleNameHTTPS**: Name of the load balancer rule for HTTPS traffic.
- **probeHTTPSName**: Name of the load balancer probe for HTTPS.
- **loadBalancerSkuName**: SKU for the load balancer.
- **wafPolicyName**: Name of the Web Application Firewall policy.
- **logWorkspaceName**: Name of the Log Analytics workspace.
- **logWorkspaceSkuName**: SKU of the Log Analytics workspace.
- **existingSubscriptionId**: Subscription ID for the existing resource group and VNet.
- **existingResourceGroupName**: Name of the existing resource group.
- **existingVnetName**: Name of the existing virtual network.

## Modules

### `createResourceGroup`

Creates a resource group within the specified subscription and location. This module accepts tags and sets them for the resource group.

- **Scope**: Subscription
- **Input**: `resourceGroupName`, `location`, `tags`

### `existingResourceGroup`

References an existing resource group that is part of a different subscription or environment.

- **Scope**: Subscription
- **Input**: `existingResourceGroupName`

### `existingVNet`

References an existing virtual network within the specified subscription and resource group.

- **Scope**: Resource Group
- **Input**: `existingVnetName`

### `createLoadBalancer`

Creates a load balancer with frontend IP configuration, backend address pools, load balancing rules, and probes. This is used for managing traffic routing and balancing.

- **Scope**: Resource Group
- **Input**: `loadBalancerName`, `frontendIPConfigurationName`, `backendAddressPoolName`, `loadBalancerRuleNameHTTPS`, `probeHTTPSName`, `loadBalancerSkuName`

### `createWAFPolicy`

Creates a Web Application Firewall (WAF) policy for the Azure Front Door. It configures policy settings such as enabling/disabling state and detection mode.

- **Scope**: Resource Group
- **Input**: `wafPolicyName`, `azureFrontDoorSKU`

### `createAzureFrontdoor`

Creates an Azure Front Door profile with custom domains, origin groups, diagnostic settings, and security policies. This module provides enhanced routing and application acceleration.

- **Scope**: Resource Group
- **Input**: `azureFrontDoorName`, `azureFrontDoorSKU`, `azureFrontDoorLocation`, `azureFrontDoorAFDEndpointName`, `hostDomainName`, `customDomainName`, `originGroupName`, `originName`, `routeName`

### `createPrivateLinkServices`

Creates a private link service that can be used for private connections to resources like load balancers. It allows secure communication with services via private IP addresses.

- **Scope**: Resource Group
- **Input**: `privateLinkServiceName`, `location`, `existingVNet`

### `createLogAnalyticsWorkspace`

Creates a Log Analytics workspace for monitoring and diagnostics. It provides insights into resources deployed in the subscription.

- **Scope**: Resource Group
- **Input**: `logWorkspaceName`, `logWorkspaceSkuName`, `location`, `tags`

## Example Usage

```bicep
module createResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  scope: subscription(subscriptionId)
  name: 'rg-${deploymentGuid}'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}

---

Let me