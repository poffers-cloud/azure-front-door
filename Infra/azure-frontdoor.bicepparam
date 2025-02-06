using 'azure-frontdoor.bicep'


//parameters for the deployment.
param updatedBy = 'demo'
param subscriptionId = ''
param environmentType = 'prod' 
param location = 'westeurope' 
param locationShortCode = 'weu' 
param productType = 'frontdoor'

//parameters for the existing resources
param existingSubscriptionId = ''
param existingVnetName = ''
param existingResourceGroupName = ''

//parameters for the resource group
param resourceGroupName = 'rg-${productType}-${environmentType}-${locationShortCode}'

//parameters for the Azure Front Door
param azureFrontDoorName = 'afd-${productType}-${environmentType}-${locationShortCode}'
param azureFrontDoorSKU = 'Premium_AzureFrontDoor'
param azureFrontDoorLocation = 'global'
param azureFrontDoorAFDEndpointName = 'afdendpoint${environmentType}${locationShortCode}'
param hostDomainName = 'demo.cloud'
param customDomainName = 'demo-cloud'
param originGroupName = 'og-group-demo-cloud'
param originName = 'og-demo-cloud'
param routeName = 'route-demo-cloud'

//parameters for the Front Door web application firewall
param wafPolicyName = 'waf${productType}${environmentType}${locationShortCode}'

//parameters for the Log Analytics Workspace
param logWorkspaceName = 'law-${productType}-${environmentType}-${locationShortCode}'
param logWorkspaceSkuName = 'PerGB2018'

//parameters for the Private Link Services
param privateLinkServiceName = 'pls-${productType}-${environmentType}-${locationShortCode}'

//parameters for the Load Balancer
param loadBalancerName = 'lb-${productType}-${environmentType}-${locationShortCode}'
param loadBalancerSkuName = 'Standard'
param frontendIPConfigurationName = 'frontendconfig${environmentType}'
param backendAddressPoolName = 'backend${environmentType}'
param loadBalancerRuleNameHTTPS = 'lb-rule-https-${environmentType}'
param probeHTTPSName = 'probe-https-${environmentType}'





