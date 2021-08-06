locals {
  prefix = "onprem"
}

resource "azurerm_resource_group" "onprem_rg" {
  name     = "${local.prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "onprem" {
  name                = "${local.prefix}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.onprem_rg.name
  address_space       = var.vnet_address_space

  tags = {
    environment = "dev"
  }
}
resource "azurerm_subnet" "onprem_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.onprem_rg.name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = var.gateway_subnet_address_space
}

resource "azurerm_subnet" "onprem_management_subnet" {
  name                 = "${local.prefix}-mgmt-subnet"
  resource_group_name  = azurerm_resource_group.onprem_rg.name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = var.management_subnet_address_space
}

resource "azurerm_network_security_group" "onprem_nsg" {
  name                = "${local.prefix}-mngmt-access-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.onprem_rg.name
}

resource "azurerm_network_security_rule" "nsg_rule" {
  name                        = "allow-inbound-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.onprem_rg.name
  network_security_group_name = azurerm_network_security_group.onprem_nsg.name
}


resource "azurerm_subnet_network_security_group_association" "onprem_mgmt_subnet_sg" {
  subnet_id                 = azurerm_subnet.onprem_management_subnet.id
  network_security_group_id = azurerm_network_security_group.onprem_nsg.id
}

resource "azurerm_public_ip" "onprem_vm_pip" {
  name                = "${local.prefix}-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.onprem_rg.name
  allocation_method   = "Dynamic"
}


resource "azurerm_network_interface" "onprem_vm_nic" {
  name                = "${local.prefix}-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.onprem_rg.name

  ip_configuration {
    name                          = "${local.prefix}-vm-ip"
    subnet_id                     = azurerm_subnet.onprem_management_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.onprem_vm_pip.id
  }

}

resource "azurerm_linux_virtual_machine" "onprem-vm" {
  name                = "${local.prefix}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.onprem_rg.name
  size                = var.vmsize
  admin_username      = var.username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.onprem_vm_nic.id,
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



output "resource_group_name" {
  value = azurerm_resource_group.onprem_rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.onprem.name
}

output "vnet_id" {
  value = azurerm_virtual_network.onprem.id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.onprem_gateway_subnet.id
}

