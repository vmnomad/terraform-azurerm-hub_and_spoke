variable "prefix"{
    type = string
}

variable "location"{
    type = string
}

variable "vnet_address_space"{
    type = list(string)
}

variable "management_subnet_address_space"{
    type = list(string)
}

variable "tags" {
    type = map(string)
}

variable "username" {
  description = "Username for Virtual Machines"
  type = string
}

variable "password" {
  description = "Password for Virtual Machines"
  type = string
  sensitive =  true
}

variable "vmsize" {
  description = "Size of the VMs"
}

variable "next_hop_ip" {
  type = string
}