output "vm_public_ips" {
  description = "Public IPs of all VMs"
  value       = [for i in aws_instance.web_vm : i.public_ip]
}

output "db_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.primary.endpoint
}
  
