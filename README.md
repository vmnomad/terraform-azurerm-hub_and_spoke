# Azure Hybrid Hub and Spoke topology with Azure Firewall

This is a simple module that creates Hub, Nx Spokes and On-Prem topology with Azure firewall controlling all Spoke inbound and outbound traffic.


The Microsoft Tutorial: [Deploy and configure Azure Firewall and policy in a hybrid network using the Azure portal](https://docs.microsoft.com/en-au/azure/firewall/tutorial-hybrid-portal-policy) was used as a guideline when creating this module.

## Warning

Always make sure you destroy everything after you finished working with it. This module might be quite expensive for a lab use if left for a while. While VMs and VPN gatways are cheap, the Azure Firewall could be incur significant cost. 
You can check latest Azure pricing [here](https://azure.microsoft.com/en-us/pricing/calculator/)

## Usage

There is an example inclued in the [Examples](./examples) folder

## Features

This module creates a standard Hybrid Hub and Spoke topology with the following features:
 - Hub vNet
 - Nx Spoke vNets
 - On-Prem vNet
 - Basic SKU VPN gateways in Hub and On-Prem vNets
 - Standard Azure Firewall in Hub vNet
 - vNet-to-vNet VPN tunnel between Hub and On-Prem vNets
 - Hub vNet peering to each Spoke vNet
 - Default route for each Spoke Management subnet pointing to Azure Firewall
 - Route to each Spoke vNet for Hub Gateway subnet
 - Standard_B1s SKU Ubuntu VM in each vNet
 - DNAT rule to access a VM in the very first spoke on Azure Firewall PIP/Port 2222
 - On-Prem VM is deployed with Public IP

## Compatibility
This module is tested with Terraform v1.0.2
 
 ## Known issues
 - DNAT uses static IP address
 - Resource Group Tags are static
 
 
