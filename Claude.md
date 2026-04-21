# Claude.md – Repository Overview

## 📁 Repository Layout
```
Ansible-EpicBook/
├─ Terraform/                 # AWS infrastructure (Terraform) + Azure lab (Terraform)
│   ├─ main.tf               # Core AWS resources (VPC, subnets, SG, EC2, RDS)
│   ├─ variables.tf          # Variables for AWS resources
│   ├─ outputs.tf            # Exported outputs
│   ├─ sectret.auto.tfvars   # Auto‑generated secrets (do NOT commit)
│   ├─ terraform.tfvars      # User‑provided variable values
│   ├─ .terraform/           # Provider plugins (auto‑generated)
│   ├─ .ssh/                 # SSH key pair used by Terraform
│   ├─ CLAUDE.md             # Guidance for Claude when working in this folder
│   └─ theepicbook/          # Embedded Git repo with additional docs
│
├─ ansible-lab/              # Azure resources provisioned via Terraform
│   ├─ main.tf               # Azure RG, VNet, Subnet, NIC, VM, NSG
│   ├─ variables.tf          # Azure variable definitions
│   └─ outputs.tf            # Exported Azure outputs
│
├─ static-web/                # Ansible playbooks & roles for the web tier
│   ├─ ansible.cfg          # Minimal SSH config for Ansible
│   ├─ inventory.ini        # Host inventory used by playbooks
│   ├─ site.yml             # Top‑level playbook that includes roles
│   ├─ roles/
│   │   ├─ common/          # Generic utilities (handlers, defaults, vars)
│   │   ├─ nginx/           # Nginx web‑server configuration (tasks, templates)
│   │   └─ epicbook/        # Custom role for the EpicBook app (templates, vars)
│   └─ group_vars/web.yml   # Group variables for the `web` group
│
├─ theepicbook/ db/          # Database schema and seed data for the EpicBook app
│   ├─ db/                 # CSV seed files and SQL schema
│   └─ Assignment4_Complete_WorkingGuide.docx
│
├─ static-web/files/         # Static site assets (HTML, etc.)
│
├─ *.md (README, docs)      # Project documentation
└─ .claude/                 # Claude Code configuration files
```

## ☁️ Terraform – AWS Deployment
- **VPC** `epicbook-vpc` (10.0.0.0/16) with a public subnet for web servers and two private subnets for databases.
- **Security Groups**:
  - `sg_web` – Allows HTTP/HTTPS from anywhere and SSH **only from your current public IP** (determined via `https://checkip.amazonaws.com`).
  - `sg_db` – Allows MySQL (3306) *only* from the web subnet.
- **EC2 Instances** – `web_vm` count driven by `var.vm_roles`; they receive a public IP and are tagged `web-vm`.
- **RDS MySQL** – Primary instance `epicbook-mysql` in a private subnet group, not publicly reachable.
- **Key Pair** – Public key from `.ssh/id_rsa.pub` is imported as `deployer`.
- **Outputs** – Provide instance IPs, RDS endpoint, etc. (see `outputs.tf`).

**Typical workflow**:
```bash
cd Terraform
terraform init        # install providers
terraform plan -var-file=sectret.auto.tfvars   # preview
terraform apply -var-file=sectret.auto.tfvars   # create resources
terraform destroy -var-file=sectret.auto.tfvars # tear down
```
> **Note:** `sectret.auto.tfvars` contains sensitive values (passwords, keys). Keep it out of version control.

### Known Issues (Terraform)
- Duplicate SSH ingress rule in `sg_web` (lines 74‑88) – one can be removed.
- Tag says *Ubuntu‑20.04* but the AMI filter selects Ubuntu 22.04 (Jammy). Adjust tag or filter for consistency.

## 🌐 Terraform – Azure Lab (ansible‑lab)
- Provisions a resource group, VNet, subnet, public IPs, NICs, NSG (allow SSH), and **Linux VMs**.
- Uses a `remote-exec` provisioner to copy your local `~/.ssh/id_rsa.pub` into the VM’s `authorized_keys` for password‑less SSH.
- Useful for experimenting with Ansible against Azure VMs.

## 📜 Ansible – Configuration Management (`static-web`)
- **Inventory** (`inventory.ini`) defines groups `web`, `app`, `db` that correspond to the Terraform‑created AWS instances.
- **Playbooks** are driven by `site.yml`, which includes the roles:
  - `common` – shared defaults, handlers, and variables.
  - `nginx` – installs Nginx, configures virtual host using `templates/epicbook.conf.j2`.
  - `epicbook` – deploys the EpicBook application (JSON config templating, static files).
- Run a quick connectivity test:
  ```bash
  ansible all -i inventory.ini -m ping
  ```
- Apply the full configuration:
  ```bash
  ansible-playbook -i inventory.ini site.yml
  ```

### Role Highlights
- **common** – contains generic tasks (e.g., installing `git`, creating users) and shared variables.
- **nginx** – template `epicbook.conf.j2` renders a server block that proxies to the app tier.
- **epicbook** – uses `templates/config.json.j2` to render a JSON config with DB credentials pulled from `group_vars/web.yml`.

## 📚 Database (`theepicbook/db`)
- **Schema** – `BuyTheBook_Schema.sql` defines tables for `authors`, `books`, etc.
- **Seed Data** – CSV files (`author.csv`, `books.csv`) and corresponding `*_seed.sql` scripts load initial data.
- The app reads from this MySQL instance provisioned by Terraform.

## 📦 Additional Files & Utilities
- `Assignment4_Complete_WorkingGuide.docx` – detailed lab instructions.
- `how_to_setup.txt` – quick‑start guide for Terraform.
- `passwordless-ssh-access.txt` – steps to copy SSH keys for password‑less access.
- `.env` (in `static-web`) – can store environment variables for local testing (not checked into VCS).
- `sectret.auto.tfvars` – **sensitive** Terraform variables (auto‑generated).

## 🛠️ Working with Claude Code
- The existing `Terraform/CLAUDE.md` already provides guidance for that sub‑directory. This top‑level `Claude.md` aggregates the whole repository so Claude can quickly understand the context.
- When you invoke Claude Code in this repo, it will read this file to know:
  1. **What the project does** (multi‑cloud infrastructure + Ansible + web app).
  2. **Where to find key artefacts** (Terraform files, Ansible roles, DB seeds).
  3. **Typical command‑line workflows** for provisioning and configuration.

## 🚧 Future Work / Open Items
- Resolve the duplicate SSH rule in the AWS security group.
- Align the instance tag with the selected Ubuntu AMI version.
- Populate the placeholder role READMEs (`static-web/roles/*/README.md`) with concrete documentation.
- Consider extracting common variables into a single `variables.tf` or `group_vars/all.yml` to reduce duplication.

---
*Generated with Claude Code*.
