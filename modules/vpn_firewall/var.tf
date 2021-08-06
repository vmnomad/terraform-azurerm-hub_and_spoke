variable "hub_location"{
    type = string
}

variable "onprem_location"{
    type = string
}

variable "hub_rg_name"{
    type = string
}

variable "onprem_rg_name"{
    type = string
}

variable "spoke_vnet_ranges" {
  type = map(string)
  description = "the list of spoke vnet IP ranges"
}

variable "onprem_vnet_range" {
    type = string
}

variable "hub_firewall_subnet_id" {
    type = string
}
variable "hub_gateway_subnet_id" {
    type = string
}

variable "onprem_gateway_subnet_id" {
    type = string
}

variable "shared_key" {
    type = string
    sensitive = true
}