resource "azurerm_resource_group" "hub_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  address_space       = var.vnet_address_space

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_group" "hub_nsg" {
  name                = "${var.prefix}-management-access-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_rg.name
}

resource "azurerm_network_security_rule" "rule" {
  name                        = "allow-inbound-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.hub_rg.name
  network_security_group_name = azurerm_network_security_group.hub_nsg.name
}

resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "gateway_subnet"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = var.gateway_subnet_address_space
}


resource "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "firewall_subnet"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = var.firewall_subnet_address_space
}

resource "azurerm_subnet" "hub_management" {
  name                 = "${var.prefix}-mgmt-subnet"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = var.management_subnet_address_space
}

resource "azurerm_subnet_network_security_group_association" "hub_mgmt_subnet_sg" {
  subnet_id                 = azurerm_subnet.hub_management.id
  network_security_group_id = azurerm_network_security_group.hub_nsg.id
}

# resource "azurerm_public_ip" "hub_vm_pip" {
#   name                = "${var.prefix}-vm-pip"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.hub_rg.name
#   allocation_method   = "Dynamic"
# }


resource "azurerm_network_interface" "hub_vm_nic" {
  name                = "${var.prefix}-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  ip_configuration {
    name                          = "${var.prefix}-vm-ip"
    subnet_id                     = azurerm_subnet.hub_management.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.hub_vm_pip.id
  }

}

resource "azurerm_linux_virtual_machine" "hub_vm" {
  name                = "${var.prefix}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  size                = var.vmsize
  admin_username      = var.username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.hub_vm_nic.id,
  ]
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}




output "hub-vm" {
  value = {
    #"Connect" : "ssh ${var.username}@${azurerm_public_ip.hub_vm_pip.ip_address}",
    "Private IP" : azurerm_network_interface.hub_vm_nic.ip_configuration[0].private_ip_address
  }
  depends_on = [azurerm_linux_virtual_machine.hub_vm]
}


output "resource_group_name" {
  value = azurerm_resource_group.hub_rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.hub_vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.hub_vnet.id
}

output "firewall_subnet_id" {
  value = azurerm_subnet.AzureFirewallSubnet.id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.GatewaySubnet.id
}

