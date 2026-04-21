output "vm_public_ips" {
  value = [for ip in azurerm_public_ip.public_ip : ip.ip_address]
}

output "ssh_access_commands" {
  value = [
    for i in range(var.vm_count) :
    "ssh ${var.admin_username}@${azurerm_public_ip.public_ip[i].ip_address}"
  ]
}
