resource "azurerm_resource_group" "spoke_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
tags = var.tags
}


resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  address_space       = var.vnet_address_space


}


resource "azurerm_subnet" "spoke_management_subnet" {
  name                 = "${var.prefix}-management-subnet"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = var.management_subnet_address_space
}


resource "azurerm_network_security_group" "spoke_nsg" {
  name                = "${var.prefix}-management-access-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
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
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.spoke_nsg.name
}


resource "azurerm_subnet_network_security_group_association" "spoke_mgmt_subnet_sg" {
  subnet_id                 = azurerm_subnet.spoke_management_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke_nsg.id
}


# resource "azurerm_public_ip" "spoke_vm_pip" {
#   name                = "${var.prefix}-vm-pip"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.spoke_rg.name
#   allocation_method   = "Dynamic"
# }


resource "azurerm_network_interface" "spoke_vm_nic" {
  name                = "${var.prefix}-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg.name

  ip_configuration {
    name                          = "${var.prefix}-vm-ip"
    subnet_id                     = azurerm_subnet.spoke_management_subnet.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.spoke_vm_pip.id
  }

}

resource "azurerm_linux_virtual_machine" "spoke_vm" {
  name                = "${var.prefix}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  size                = var.vmsize
  admin_username      = var.username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.spoke_vm_nic.id,
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

# routing to spoke2
resource "azurerm_route_table" "spoke_route_table" {
  name                          = "${var.prefix}-route-table"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.spoke_rg.name
  disable_bgp_route_propagation = true

}


resource "azurerm_route" "routes_to_spokes" {
  name                   = "defaul-route" 
  resource_group_name    = azurerm_resource_group.spoke_rg.name
  route_table_name       = azurerm_route_table.spoke_route_table.name
  address_prefix         =  "0.0.0.0/0"
  next_hop_type  = "VirtualAppliance" 
  next_hop_in_ip_address = var.next_hop_ip
}


resource "azurerm_subnet_route_table_association" "subnet_route_table" {
  subnet_id      = azurerm_subnet.spoke_management_subnet.id
  route_table_id = azurerm_route_table.spoke_route_table.id
}



# Outputs to be used for peering
output "resource_group_name" {
  value = azurerm_resource_group.spoke_rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.spoke_vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.spoke_vnet.id
}


output "spoke-vm" {
  value = {
    # "Connect" : "ssh ${var.username}@${azurerm_public_ip.spoke_vm_pip.ip_address}",
    "Private IP" : azurerm_network_interface.spoke_vm_nic.ip_configuration[0].private_ip_address
  }
}
