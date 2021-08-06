variable "hub_prefix" {
  type        = string
  description = "Hub prefix"
}

variable "hub_location" {
  description = "Location of the hub vNet"
}

variable "hub_vnet_address_space" {
  description = "Hub virtual network address space"
}
variable "hub_management_subnet_address_space" {
  description = "Management subnet"
}

variable "hub_gateway_subnet_address_space" {
  description = "Gateway subnet"
}

variable "firewall_subnet_address_space" {
  description = "Firewall subnet"
}


# spoke variables
variable "spokes" {
  type = map(object(
    {
      location                        = string
      vnet_address_space              = string
      management_subnet_address_space = string
    }
  ))
}

# on prem variables
variable "onprem_location" {
  description = "Location of the hub vNet"
}

variable "onprem_vnet_address_space" {
  description = "Hub virtual network address space"
}
variable "onprem_management_subnet_address_space" {
  description = "Management subnet"
}

variable "onprem_gateway_subnet_address_space" {
  description = "Gateway subnet"
}


# common variables
variable "username" {
  type        = string
  description = "Username for Virtual Machines"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Password for Virtual Machines"

}

variable "vmsize" {
  type        = string
  description = "Size of the VMs"
  default     = "Standard_B1s"
}



variable "vpn_shared_key" {
  type      = string
  sensitive = true
}
