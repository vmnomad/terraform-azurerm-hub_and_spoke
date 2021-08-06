terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

module "hub_and_spoke" {
    source = "ithub.com/vmnomad/terraform-azurerm-hub_and_spoke" 

    # hub configuration
    hub_location                        = "australiaeast"
    hub_prefix                          = "hub"
    hub_vnet_address_space              = "10.0.0.0/22"
    hub_management_subnet_address_space = "10.0.0.0/24"
    firewall_subnet_address_space       = "10.0.3.128/26"
    hub_gateway_subnet_address_space    = "10.0.3.224/27"

    # spokes configuration
    spokes = {
      spoke1 = {
          location                        = "australiaeast"
          vnet_address_space              = "10.0.4.0/22"
          management_subnet_address_space = "10.0.4.0/24"
      }
      spoke2 = {
          location                        = "australiaeast"
          vnet_address_space              = "10.0.8.0/22"
          management_subnet_address_space = "10.0.8.0/24"
      }

      # add extra spokes if needed
      # spoke3 = {
      #   location                        = "australiaeast"
      #   vnet_address_space              = "10.0.12.0/22"
      #   management_subnet_address_space = "10.0.12.0/24"

      # }
    }

    # on prem configuration
    onprem_location                        = "australiaeast"
    onprem_vnet_address_space              = "10.0.64.0/22"
    onprem_management_subnet_address_space = "10.0.64.0/24"
    onprem_gateway_subnet_address_space    = "10.0.67.224/27"


    # common configuration
    username = "azureadmin"
    password = "adminadmin123!"
    vmsize   = "Standard_B1s"

    vpn_shared_key = "VMware1!"
}
    