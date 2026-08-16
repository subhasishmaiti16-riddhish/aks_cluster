# AKS Cluster Infrastructure — Terraform DevSecOps Pipeline

Production-ready Azure Kubernetes Service (AKS) cluster deployed using Terraform with a GitHub Actions DevSecOps pipeline using Azure OIDC authentication.

---

## 📁 Project Structure

```
aks_cluster/
├── .github/
│   └── workflows/
│       └── terraform.yml           # GitHub Actions CI/CD pipeline
├── parent/                         # Root module
│   ├── main.tf                     # Calls all child modules
│   ├── variables.tf                # Variable declarations
│   ├── terraform.tfvars            # Variable values
│   └── providers.tf                # Azure provider + backend config
└── environtment/                   # Child modules
    ├── rg/
    │   └── main.tf                 # Resource Group module
    ├── vnet/
    │   └── main.tf                 # Virtual Network module
    ├── subnet/
    │   └── main.tf                 # Subnet module
    └── aks/
        └── main.tf                 # AKS Cluster module
```

---

## 🏗️ Infrastructure Overview

| Resource | Name | Details |
|---|---|---|
| Resource Group | `rg-aks` | Central India |
| Virtual Network | `vnet-aks` | `10.0.0.0/16` |
| Subnet (Control Plane) | `subnet-aks` | `10.0.1.0/24` |
| Subnet (Node Pool) | `subnet-aks-node` | `10.0.2.0/24` |
| AKS Cluster | `aks-cluser` | Kubernetes 1.35, Standard_D2_v5 |

---

## 🧩 Terraform Modules

### Parent Module (`parent/main.tf`)

```hcl
module "rg_parent" {
  source = "../environtment/rg"
  rg     = var.rg_parent
}

module "vnet_parent" {
  depends_on = [module.rg_parent]
  source     = "../environtment/vnet"
  vnet       = var.vnet_parent
}

module "subnet_parent" {
  depends_on = [module.vnet_parent]
  source     = "../environtment/subnet"
  subnet     = var.subnet_parent
}

module "aks_parent" {
  depends_on = [module.subnet_parent, module.rg_parent]
  source     = "../environtment/aks"
  aks        = var.aks_parent
}
```

### Child Modules

**Resource Group (`environtment/rg/main.tf`)**
```hcl
resource "azurerm_resource_group" "rg-test" {
  for_each = var.rg
  name     = each.value.rg_name
  location = each.value.location
}
```

**Virtual Network (`environtment/vnet/main.tf`)**
```hcl
resource "azurerm_virtual_network" "vnet" {
  for_each            = var.vnet
  name                = each.value.vnet_name
  resource_group_name = each.value.rg_name
  location            = each.value.location
  address_space       = each.value.address_space
}
```

**Subnet (`environtment/subnet/main.tf`)**
```hcl
resource "azurerm_subnet" "subnet" {
  for_each             = var.subnet
  name                 = each.value.subnet_name
  resource_group_name  = each.value.rg_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes
}
```

**AKS Cluster (`environtment/aks/main.tf`)**
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  for_each            = var.aks
  name                = each.value.aks_name
  location            = each.value.location
  resource_group_name = each.value.rg_name
  dns_prefix          = "subhasish1"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v5"
    vnet_subnet_id = data.azurerm_subnet.subnet_data[each.key].id

    upgrade_settings {
      max_surge = "10%"
    }
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}
```

---

## ⚙️ Variable Values (`terraform.tfvars`)

```hcl
rg_parent = {
  rg1 = {
    rg_name  = "rg-aks"
    location = "centralindia"
  }
}

vnet_parent = {
  vnet1 = {
    vnet_name     = "vnet-aks"
    rg_name       = "rg-aks"
    location      = "centralindia"
    address_space = ["10.0.0.0/16"]
  }
}

subnet_parent = {
  subnet1 = {
    subnet_name      = "subnet-aks"
    rg_name          = "rg-aks"
    vnet_name        = "vnet-aks"
    address_prefixes = ["10.0.1.0/24"]
  }
  subnet2 = {
    subnet_name      = "subnet-aks-node"
    rg_name          = "rg-aks"
    vnet_name        = "vnet-aks"
    address_prefixes = ["10.0.2.0/24"]
  }
}

aks_parent = {
  aks1 = {
    aks_name    = "aks-cluser"
    location    = "centralindia"
    rg_name     = "rg-aks"
    subnet_name = "subnet-aks-node"
    vnet_name   = "vnet-aks"
  }
}
```

---

## 🗄️ Terraform Backend

State is stored remotely in Azure Storage Account:

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.81.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg_provider"
    storage_account_name = "aksstorageaccount3"
    container_name       = "aksstoragecont"
    key                  = "parent.aksstoragecont"
  }
}
```

---

## 🔄 CI/CD Pipeline

The GitHub Actions pipeline has **3 stages**:

```
feature/** push ──→ Feature - Terraform Plan
                      (init, fmt, validate, plan)

main push ──→ Main - Terraform Plan ──→ [Upload Artifact]
                (init, fmt, validate, plan)
                          │
                          ▼
              [Manual Approval Required]
                          │
                          ▼
              Production Approval and Apply
                (init, download artifact, apply)
```

### Pipeline Jobs

| Job | Trigger | Steps |
|---|---|---|
| Feature - Terraform Plan | `feature/**` push or PR | init → fmt → validate → plan |
| Main - Terraform Plan | `main` push | init → fmt → validate → plan → upload artifact |
| Production Approval and Apply | `main` push (after approval) | init → download artifact → apply |

---

## 🔐 Authentication — Azure OIDC

No secrets stored — uses **Federated Identity Credentials**.

### GitHub Secrets Required

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App Registration Client ID |
| `AZURE_TENANT_ID` | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID |

### Azure Federated Credentials

| Credential Name | Entity Type | Subject |
|---|---|---|
| `github-aks-feature-plan` | Branch | `feature/aks_cluster` |
| `github-aks-cluster-pullrequest` | Pull Request | `pull_request` |
| `aks-cluster-main-oidc` | Branch | `main` |
| `aks-cluster-production-oidc` | Environment | `production` |

> **Note:** GitHub sends subject identifier in format:
> `repo:ORG@ORG_ID/REPO@REPO_ID:ref:refs/heads/BRANCH`
> Use "Edit (optional)" in Azure Portal to set the exact subject.

---

## 🌿 Branching Strategy

```
main                     ← Production branch
└── feature/aks_cluster  ← Feature development
```

1. Create a feature branch
2. Make changes and push
3. Pipeline runs `terraform plan` automatically
4. Open PR to `main`
5. Merge PR → triggers Main plan + Production approval
6. Approve in GitHub → `terraform apply` runs

---

## 🔧 Local Development

```bash
# Clone the repo
git clone https://github.com/subhasishmaiti16-riddhish/aks_cluster.git
cd aks_cluster/parent

# Login to Azure
az login

# Initialize Terraform
terraform init

# Plan
terraform plan

# Apply (only locally)
terraform apply
```

---

## ⚠️ Important Notes

- `upgrade_settings.max_surge = "10%"` must be set to avoid state drift
- Never manually apply in production — always use the pipeline
- Each pipeline trigger (feature, PR, main, production) needs its own Azure federated credential
- Backend state key must be unique per project to avoid state conflicts
- Terraform attribute names must use `_` (underscore), never `-` (dash)

---

## 👤 Author

**subhasishmaiti16-riddhish**
