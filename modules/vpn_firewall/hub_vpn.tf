resource "azurerm_public_ip" "hub_vpn_gateway_pip" {
  name                = "hub-vpn-gateway-pip"
  location            = var.hub_location
  resource_group_name = var.hub_rg_name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "hub_vpn_gateway" {
  name                = "hub-vpn-gateway"
  location            = var.hub_location
  resource_group_name = var.hub_rg_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.hub_vpn_gateway_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.hub_gateway_subnet_id
  }
    # P2S client config, can't be used with Basic SKU
#   vpn_client_configuration {
#     aad_audience         = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
#     aad_issuer           = "https://sts.windows.net/3b65c092-7b6b-4027-9d96-972c2ddda512/"
#     aad_tenant           = "https://login.microsoftonline.com/3b65c092-7b6b-4027-9d96-972c2ddda512/"
#     address_space        = ["192.168.3.0/24"]
#     vpn_client_protocols = ["OpenVPN"]
#   }
}


resource "azurerm_route_table" "gateway_route_table" {
  name                          = "gateway-route-table"
  location                      = var.hub_location
  resource_group_name           = var.hub_rg_name
  disable_bgp_route_propagation = false
}

resource "azurerm_route" "routes_to_spokes" {
 for_each = var.spoke_vnet_ranges
  name                   = "route-to-${each.key}"
  resource_group_name    = var.hub_rg_name
  route_table_name       = azurerm_route_table.gateway_route_table.name
  address_prefix         =  each.value
  next_hop_type  = "VirtualAppliance" 
  next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
}


resource "azurerm_subnet_route_table_association" "gateway_route_table" {
  subnet_id      = var.hub_gateway_subnet_id
  route_table_id = azurerm_route_table.gateway_route_table.id
}



resource "azurerm_virtual_network_gateway_connection" "hub_onprem_connection" {
  name                = "hub-onprem-conn"
  location            = var.hub_location
  resource_group_name = var.hub_rg_name

  type           = "Vnet2Vnet"
  routing_weight = 1

  virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub_vpn_gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem_vpn_gateway.id

  shared_key = var.shared_key
}