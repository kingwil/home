@description('Password for the Jump and Workstation VMs')
@secure()
param AdminPassword string = 'Pass@w0rd$$$'

@description('The defualt username for the administrator user')
param AdminUser string = 'LabAdmin'

@description('Virtual Machine Size')
param VMSize string = 'Standard_B1ms'

var vm_dc1_nic_name = 'srv-dc1-nic'
var vm_dc1_name = 'srv-dc1'
var vnet_name = 'test-vnet'
var pip_name = 'bastion-pip'
var subnet_name = 'tier0-subnet'
var dc_ip = '10.0.2.5'
var nsg_name = 'tier0-nsg'
var bastion_name = 'xdr-bastion'

resource pip_resource 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: pip_name
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  sku: {
    name: 'Standard'
  }
}

resource subnet_resource 'Microsoft.Network/virtualNetworks/subnets@2020-04-01' = {
  name: '${vnet_resource.name}/${subnet_name}'
  dependsOn: [
    vnet_resource
    nsg_resource
  ]
  properties: {
    addressPrefix: '10.0.2.0/24'
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    networkSecurityGroup: {
      id: nsg_resource.id
    }
  }
}

resource nic_vm_dc1_resource 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vm_dc1_nic_name
  location: resourceGroup().location
  dependsOn: [
    pip_resource
    subnet_resource
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: dc_ip
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet_resource.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource vm_dc1_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vm_dc1_name
  location: resourceGroup().location
  dependsOn: [
    nic_vm_dc1_resource
  ]
  properties: {
    hardwareProfile: {
      vmSize: VMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${vm_dc1_name}_OsDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: vm_dc1_name
      adminUsername: AdminUser
      adminPassword: AdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic_vm_dc1_resource.id
        }
      ]
    }
    licenseType: 'Windows_Server'
  }
}

resource vm_dc1_script_extension_resource 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${vm_dc1_resource.name}/Microsoft.Powershell'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings:{
      fileUris: [
        'https://raw.githubusercontent.com/kingwil/home/master/ADDS%20DSC%20Automation%20Account/adds/Enable_RebootIfNeededLCM.ps1'
        ]
        commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Enable_RebootIfNeededLCM.ps1'
    }
  }
}

resource vm_dc1_dsc_extension_resource 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${vm_dc1_resource.name}/Microsoft.Powershell.DSC'
  dependsOn: [
    vm_dc1_script_extension_resource
  ]
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.83'
    autoUpgradeMinorVersion: true
    settings: {
      configuration: {
        url: 'https://github.com/kingwil/home/raw/master/ADDS%20DSC%20Automation%20Account/adds/config-adds.ps1.zip'
        script: 'config-adds.ps1'
        function: 'config-adds'
      }
    }
    protectedSettings: {
      configurationArguments: {
        Credential: {
          userName: AdminUser
          password: AdminPassword
        }
      }
    }
  }
}

resource vnet_resource 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: vnet_name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
  dependsOn: []
}

resource nsg_resource 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsg_name
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'ALLOW-RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: dc_ip
          access: 'Allow'
          priority: 1234
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource subnet_bastion_resource 'Microsoft.Network/virtualNetworks/subnets@2020-04-01' = {
  name: '${vnet_resource.name}/AzureBastionSubnet'
  dependsOn: [
    vnet_resource
    subnet_resource
  ]
  properties: {
    addressPrefix: '10.0.0.0/27'
  }
}

resource bastion_resource 'Microsoft.Network/bastionHosts@2020-07-01' = {
  name: bastion_name
  dependsOn: [
    subnet_bastion_resource
  ]
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        properties: {
          subnet: {
            id: subnet_bastion_resource.id
          }
          publicIPAddress: {
            id: pip_resource.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: 'bastionIpConf'
      }
    ]
  }
}
