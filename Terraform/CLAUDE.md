# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform project that provisions AWS infrastructure for a multi-tier application deployment, with Ansible for configuration management. It creates 4 EC2 instances: 2 web servers, 1 app server, and 1 database server.

## Commands

### Terraform Workflow
```bash
terraform init          # Initialize Terraform
terraform plan          # Preview changes
terraform apply         # Apply infrastructure
terraform destroy       # Tear down infrastructure
```

### Ansible
```bash
ansible all -i inventory.ini -m ping                    # Test connectivity
ansible-playbook -i inventory.ini playbook.yml          # Run playbook
```

## Architecture

**Infrastructure (main.tf):**
- Custom VPC (10.0.0.0/16) with single public subnet (10.0.1.0/24)
- Internet gateway + route table for public access
- Security group restricts SSH (port 22) to the local machine's public IP only
- 4x t3.micro Ubuntu 22.04 instances with roles defined in `vm_roles` variable

**Instance Roles (variables.tf):**
- `web1`, `web2` - Web tier (inventory group: `[web]`)
- `app1` - Application tier (inventory group: `[app]`)
- `db1` - Database tier (inventory group: `[db]`)

**SSH Access:**
- Key pair imported from `.ssh/id_rsa.pub`
- WSL users: Copy keys to `~/.ssh/` with proper permissions (see `passwordless-ssh-access.txt`)

## Known Issues

- `main.tf` has a duplicate SSH ingress rule (lines 74-88) - one should be removed
- Instance tag says "Ubuntu-20.04" but AMI filter selects Ubuntu 22.04 (jammy)