# let's grab all vnet ranges in spokes. These ranges will be used to allow 
# all traffic between spokes in firewall
locals {
  vnet_ranges = {for k, v in var.spokes : k => v.vnet_address_space}
}

# firstly, we want to create a hub infra
module "hub" {
  source = "./modules/hub"

  prefix                          = var.hub_prefix
  location                        = var.hub_location
  vnet_address_space              = [var.hub_vnet_address_space]
  gateway_subnet_address_space    = [var.hub_gateway_subnet_address_space]
  firewall_subnet_address_space   = [var.firewall_subnet_address_space]
  management_subnet_address_space = [var.hub_management_subnet_address_space]

  tags = {
    environment = "production"
    cost_centre = "12345"
  }

  username = var.username
  password = var.password
  vmsize   = var.vmsize

}

# and here we prepare onprem infra
module "onprem" {
  source = "./modules/onprem"

  location                        = var.onprem_location
  vnet_address_space              = [var.onprem_vnet_address_space]
  management_subnet_address_space = [var.onprem_management_subnet_address_space]
  gateway_subnet_address_space    = [var.onprem_gateway_subnet_address_space]

  tags = { #TBD
    environment = "production"
    cost_centre = "12345"
  }

  username = var.username
  password = var.password
  vmsize   = var.vmsize
}

# now we can deploy vpn gateways and azure firewall
module "vpn_firewall" {
  source = "./modules/vpn_firewall"

  hub_location    = var.hub_location
  onprem_location = var.onprem_location

  hub_rg_name    = module.hub.resource_group_name
  onprem_rg_name = module.onprem.resource_group_name

  spoke_vnet_ranges        = local.vnet_ranges
  hub_firewall_subnet_id   = module.hub.firewall_subnet_id
  hub_gateway_subnet_id    = module.hub.gateway_subnet_id
  onprem_gateway_subnet_id = module.onprem.gateway_subnet_id
  onprem_vnet_range = var.onprem_vnet_address_space

  shared_key               = var.vpn_shared_key
  depends_on = [module.hub, module.onprem]
}

# time to create infra for spokes and their default routes
module "spoke" {
  source   = "./modules/spoke"
  for_each = var.spokes

  prefix                          = each.key
  location                        = each.value.location
  vnet_address_space              = [each.value.vnet_address_space]
  management_subnet_address_space = [each.value.management_subnet_address_space]
  tags = {
    environment = "production"
    cost_centre = "12345"
  }

  #remote_spokes = { for k, v in var.spokes : k => v.vnet_address_space if k != each.key }
  next_hop_ip   = module.vpn_firewall.firewall_private_ip

  username = var.username
  password = var.password
  vmsize   = var.vmsize
  depends_on = [module.vpn_firewall]
}

# finally let's create peerings 
resource "azurerm_virtual_network_peering" "hub-spokes-peering" {
  for_each                     = module.spoke
  name                         = "hub-${each.key}-peering"
  resource_group_name          = module.hub.resource_group_name
  virtual_network_name         = module.hub.vnet_name
  remote_virtual_network_id    = each.value.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  depends_on                   = [module.spoke]
}

resource "azurerm_virtual_network_peering" "spokes-hub-peering" {
  for_each                     = module.spoke
  name                         = "${each.key}-hub-peering"
  resource_group_name          = each.value.resource_group_name
  virtual_network_name         = each.value.vnet_name
  remote_virtual_network_id    = module.hub.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
  depends_on                   = [module.spoke, azurerm_virtual_network_peering.hub-spokes-peering]
}


output "hub" {
  value = module.hub[*]
}

output "spoke" {
  value = module.spoke[*]
}