targetScope = 'subscription'

param updatedBy string

@description('Environment Type: example prod.')
@allowed([
  'test'
  'dev'
  'prod'
  'acc'
  'poc'
])
param environmentType string

param subscriptionId string

@description('Unique identifier for the deployment')
param deploymentGuid string = newGuid()

@description('Product Type: example listed below')
@allowed([
  'frontdoor'
  'firewall'
  'network'
  'avd'
])
param productType string

@description('Azure Region to deploy the resources in.')
@allowed([
  'westeurope'
  'northeurope'
])
param location string = 'westeurope'

@description('Location shortcode')
param locationShortCode string 

@description('Add tags as required as Name:Value')
param tags object = {
  Environment: environmentType
  LastUpdatedOn: utcNow('d')
  LastDeployedBy: updatedBy
}

//resource group parameters
param resourceGroupName string 

//azure front door parameters
param azureFrontDoorName string
param azureFrontDoorSKU string
param azureFrontDoorLocation string
param azureFrontDoorAFDEndpointName string
param hostDomainName string
param customDomainName string
param originGroupName string
param originName string
param routeName string

//private link parameters
param privateLinkServiceName string

//load balancer parameters
param loadBalancerName string
param frontendIPConfigurationName string
param backendAddressPoolName string

// param backendAddressPoolName2 string
param loadBalancerRuleNameHTTPS string
param probeHTTPSName string
param loadBalancerSkuName string

//waf policy parameters
param wafPolicyName string

//log analytics workspace parameters
param logWorkspaceName string
param logWorkspaceSkuName string

param existingSubscriptionId string 
param existingResourceGroupName string 
param existingVnetName string 

module createResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  scope: subscription(subscriptionId)
  name: 'rg-${deploymentGuid}'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}


resource existingResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: existingResourceGroupName
  location: location
  tags: tags
}

resource existingVNet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: existingVnetName
  scope: resourceGroup(existingSubscriptionId, existingResourceGroupName)
}

module createLoadBalancer 'br/public:avm/res/network/load-balancer:0.4.1' = {
  scope: resourceGroup(resourceGroupName)
  name: 'lb-${deploymentGuid}'
  params: {
    name: loadBalancerName 
    location: location
    frontendIPConfigurations: [
      {
        name: frontendIPConfigurationName
        subnetId: existingVNet.properties.subnets[3].id
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPoolName
      }
    ]
    loadBalancingRules: [
      {
        backendAddressPoolName: backendAddressPoolName
        backendPort: 0
        disableOutboundSnat: true
        enableFloatingIP: true
        enableTcpReset: false
        frontendIPConfigurationName: frontendIPConfigurationName
        frontendPort: 0
        idleTimeoutInMinutes: 4
        loadDistribution: 'Default'
        name: loadBalancerRuleNameHTTPS
        probeName: probeHTTPSName
        protocol: 'All'
      }
    ]   
    skuName: loadBalancerSkuName
    probes: [
      {
        intervalInSeconds: 5
        name: probeHTTPSName
        numberOfProbes: 2
        port: '443'
        protocol: 'Tcp'
      }
    ]
    tags: tags
  }
}

module createWAFPolicy 'br/public:avm/res/network/front-door-web-application-firewall-policy:0.3.1'= {
  scope: resourceGroup(resourceGroupName)
  name: 'waf-${deploymentGuid}'
  params: {
    name: wafPolicyName
    sku: azureFrontDoorSKU
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Detection'
      }
    

  
  }
}

module createAzureFrontdoor 'br/public:avm/res/cdn/profile:0.11.1' = {
  scope: resourceGroup(resourceGroupName)
  name: 'afd-${deploymentGuid}'
  params: {
    name: azureFrontDoorName
    sku: azureFrontDoorSKU
    diagnosticSettings: [
      {
        name: 'customSetting'
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
        workspaceResourceId: createLogAnalyticsWorkspace.outputs.resourceId
      }
    ]
    tags: tags
    location: azureFrontDoorLocation
    originResponseTimeoutSeconds: 60
    endpointName: 'afd-endpoint'
    customDomains: [
      {
        name: customDomainName
        hostName: hostDomainName
        certificateType: 'ManagedCertificate'
      }
    ]
    originGroups: [
      {
        name: originGroupName
      


        loadBalancingSettings: {
          additionalLatencyInMilliseconds: 50
          sampleSize: 4
          successfulSamplesRequired: 3
        }
        origins: [
          {
            name: originName
            hostName: hostDomainName
            sharedPrivateLinkResource: {
              privatelink: {
              id: createPrivateLinkServices.outputs.resourceId
              }
              privateLinkLocation: location
              requestMessage: 'allow'
             }
            
          }
        ]
      }
    ]
    afdEndpoints: [
      {
        name: azureFrontDoorAFDEndpointName
        routes: [
          {
            name: routeName
            originGroupName: originGroupName
            customDomainNames: [customDomainName]

          }
        ]
      }
    ]
    securityPolicies: [
        {
          name: 'sec-policy'
          
          associations: [
            {
              domains: [
                {
                  id:'/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroupName}/providers/Microsoft.Cdn/profiles/${azureFrontDoorName}/afdendpoints/${azureFrontDoorAFDEndpointName}'
                }
             
                ]
              patternsToMatch: [
                '/*'
              ]
            }

          ]
          wafPolicyResourceId: createWAFPolicy.outputs.resourceId
        }
      ]
  }

  dependsOn: [createResourceGroup, createLoadBalancer]
}

module createPrivateLinkServices 'br/public:avm/res/network/private-link-service:0.2.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'pls-${deploymentGuid}'
  params: {
    name: privateLinkServiceName
    location: location

    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: existingVNet.properties.subnets[4].id
          }
        }
      }
    ]
    loadBalancerFrontendIpConfigurations: [
      {
         id: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/frontendIPConfigurations/${frontendIPConfigurationName}'
      }
    ]

    autoApproval: {

      subscriptions: [
        '*'
      ]
    }

    visibility: {
      subscriptions: [
        subscription().subscriptionId
      ]
    }
    
    enableProxyProtocol: true
    tags: tags
  }
  dependsOn: [createResourceGroup, createLoadBalancer]
}

module createLogAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.10.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'law-${deploymentGuid}'
  params: {
    name: logWorkspaceName
    skuName: logWorkspaceSkuName
    location: location
    tags: tags
  }
  dependsOn: [createResourceGroup]
}





