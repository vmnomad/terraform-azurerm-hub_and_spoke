locals {
    vnet_ranges = [for k,v in var.spoke_vnet_ranges: v]
}

resource "azurerm_public_ip" "hub_firewall_pip" {
  name                = "hub-firewall-pip"
  location            = var.hub_location
  resource_group_name = var.hub_rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "hub_firewall" {
  name                = "hub-firewall"
  location            = var.hub_location
  resource_group_name = var.hub_rg_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.hub_firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.hub_firewall_pip.id
  }
}


resource "azurerm_firewall_network_rule_collection" "firewall_network_rules" {
  name                = "network-rules"
  azure_firewall_name = azurerm_firewall.hub_firewall.name
  resource_group_name = var.hub_rg_name
  priority            = 100
  action              = "Allow"

  rule {
    name = "internal-traffic"
    source_addresses = local.vnet_ranges
    destination_addresses = local.vnet_ranges
    protocols = ["Any"]
    destination_ports = ["*"]
  }

  rule {
    name = "onprem-to-azure-traffic"
    source_addresses = [var.onprem_vnet_range]
    destination_addresses = local.vnet_ranges
    protocols = ["Any"]
    destination_ports = ["*"]
  }
}

resource "azurerm_firewall_nat_rule_collection" "firewall_nat_rules" {
  name                = "nat-rules"
  azure_firewall_name = azurerm_firewall.hub_firewall.name
  resource_group_name = var.hub_rg_name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "ssh access"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "2222",
    ]

    destination_addresses = [
      azurerm_public_ip.hub_firewall_pip.ip_address
    ]

    translated_port = "22"

    translated_address = "10.0.4.4"

    protocols = [
      "TCP",
    ]
  }
}


output "firewall_private_ip" {
  value = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
}