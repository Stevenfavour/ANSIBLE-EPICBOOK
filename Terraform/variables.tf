
variable "vm_roles" {
  description = "Roles for each VM"
  type        = list(string)
  default     = ["web1"]
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}



variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "mysql_admin_user" {
  description = "MySQL admin login"
  type        = string
  default     = "mysqladmin"
}


variable "db_password" {
  description = "RDS MySQL admin password"
  type        = string
  sensitive   = true
}