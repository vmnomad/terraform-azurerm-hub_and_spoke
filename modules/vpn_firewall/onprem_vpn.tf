

resource "azurerm_public_ip" "onprem_vpn_gateway_pip" {
  name                = "onprem_vpn-gatewauy-pip"
  location            = var.onprem_location
  resource_group_name = var.onprem_rg_name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "onprem_vpn_gateway" {
  name                = "onprem-vpn-gateway"
  location            = var.onprem_location
  resource_group_name = var.onprem_rg_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.onprem_vpn_gateway_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.onprem_gateway_subnet_id
  }
}

resource "azurerm_virtual_network_gateway_connection" "onprem-hub-connection" {
  name                            = "onprem-hub-conn"
  location                        = var.onprem_location
  resource_group_name             = var.onprem_rg_name
  type                            = "Vnet2Vnet"
  routing_weight                  = 1
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.onprem_vpn_gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.hub_vpn_gateway.id

  shared_key = var.shared_key
}