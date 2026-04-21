terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------------------------------
# VPC and Subnets
# -------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "epicbook-vpc"
  }
}

resource "aws_subnet" "web" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "web-subnet"
  }
}

resource "aws_subnet" "db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "db-subnet"
  }
}

resource "aws_subnet" "db2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "db-subnet-2"
  }
}


# -------------------------------------------------
# Internet Gateway and Routing
# -------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "epicbook-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "web_rt" {
  subnet_id      = aws_subnet.web.id
  route_table_id = aws_route_table.public.id
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}


# -------------------------------------------------
# Security Groups
# -------------------------------------------------
resource "aws_security_group" "sg_web" {
  name        = "web-sg"
  description = "Allow HTTP, HTTPS and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # chomp() removes the hidden newline character from the website response
  cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg-web"
  }
}

resource "aws_security_group" "sg_db" {
  name        = "db-sg"
  description = "Allow MySQL from web subnet"
  vpc_id      = aws_vpc.main.id


  ingress {
    description = "MySQL from web subnet"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.web.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg-db"
  }
}




# -------------------------------------------------
# EC2 Instances
# -------------------------------------------------
# Find latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Optional key pair (create from provided public key if none supplied)
resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_public_key 
  public_key = file("${path.module}/.ssh/id_rsa.pub")
}

resource "aws_instance" "web_vm" {
  count                       = length(var.vm_roles)
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.web.id
  vpc_security_group_ids      = [aws_security_group.sg_web.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  tags = {
    Name = "web-vm"
  }
}

# -------------------------------------------------
# RDS MySQL Primary and Replica
# -------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "epicbook-db-subnet-group"
  subnet_ids = [aws_subnet.db.id, aws_subnet.db2.id]
  tags = {
    Name = "epicbook-db-subnet-group"
  }
}

resource "aws_db_instance" "primary" {
  identifier                = "epicbook-mysql"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = var.db_instance_class
  allocated_storage         = 20
  backup_retention_period   = 7
  apply_immediately         = true
  db_name                   = "epicbook"
  username                  = var.mysql_admin_user
  password                  = var.db_password
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.sg_db.id]
  skip_final_snapshot       = true
  publicly_accessible       = false
  multi_az                  = false
  tags = {
    Name = "primary-db"
  }

   depends_on = [
    aws_instance.web_vm
  ]
}



# -------------------------------------------------
# Private DNS (Route53 Private Hosted Zone)
# -------------------------------------------------
# Route53 private zone removed for simplicity

# DNS records for RDS removed (zone not created)

# -------------------------------------------------
# Data sources
# -------------------------------------------------
# Availability zones list
data "aws_availability_zones" "available" {}
