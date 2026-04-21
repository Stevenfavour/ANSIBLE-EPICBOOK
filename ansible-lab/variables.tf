variable "vm_count" {
  default = 4
}

variable "admin_username" {
  default = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}
