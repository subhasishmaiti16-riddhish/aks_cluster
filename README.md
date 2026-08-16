# AKS Cluster Infrastructure

A production-ready Azure Kubernetes Service (AKS) cluster deployed using Terraform with a GitHub Actions DevSecOps pipeline.

---

## 📁 Project Structure

```
aks_cluster/
├── .github/
│   └── workflows/
│       └── terraform.yml       # GitHub Actions CI/CD pipeline
├── parent/
│   ├── main.tf                 # Root module - calls child modules
│   ├── variables.tf            # Variable declarations
│   ├── terraform.tfvars        # Variable values
│   └── providers.tf            # Azure provider + backend config
└── child/
    ├── rg/
    │   └── main.tf             # Resource Group module
    ├── vnet/
    │   └── main.tf             # Virtual Network module
    ├── subnet/
    │   └── main.tf             # Subnet module
    └── aks/
        └── main.tf             # AKS Cluster module
```

---

## 🏗️ Infrastructure Overview

| Resource | Name | Details |
|---|---|---|
| Resource Group | `rg-aks` | Central India |
| Virtual Network | `vnet-aks` | 10.0.0.0/16 |
| Subnet (Control) | `subnet-aks` | 10.0.1.0/24 |
| Subnet (Nodes) | `subnet-aks-node` | 10.0.2.0/24 |
| AKS Cluster | `aks-cluser` | Kubernetes 1.35 |

---

## 🔄 CI/CD Pipeline

The GitHub Actions pipeline (`terraform.yml`) has 3 stages:

### 1. Feature Branch — Terraform Plan
- Triggers on `feature/**` branches
- Runs: `init` → `fmt` → `validate` → `plan`
- Used for development and code review

### 2. Main Branch — Terraform Plan
- Triggers on `push` to `main`
- Runs: `init` → `fmt` → `validate` → `plan`
- Uploads plan as artifact for production job

### 3. Production — Approval + Apply
- Requires manual approval via GitHub Environment protection
- Downloads plan artifact from Main job
- Runs: `terraform apply`

```
feature/** push → Feature Plan
                        ↓
main push → Main Plan → [Manual Approval] → Production Apply
```

---

## 🔐 Authentication

Uses **Azure OIDC Federated Identity** (no secrets stored):

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

---

## 🗄️ Terraform Backend

State is stored remotely in Azure Storage:

```hcl
backend "azurerm" {
  resource_group_name  = "rg_provider"
  storage_account_name = "aksstorageaccount"
  container_name       = "tfstate"
  key                  = "aks.terraform.tfstate"
}
```

---

## 🚀 AKS Configuration

```hcl
default_node_pool {
  name       = "default"
  node_count = 1
  vm_size    = "Standard_D2_v5"

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
```

---

## 📋 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.9.8
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure Subscription
- GitHub repository with Actions enabled

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

# Apply
terraform apply
```

---

## 🌿 Branching Strategy

```
main                    # Production branch
└── feature/aks_cluster # Feature development branch
```

- Always create a feature branch for changes
- Open PR to `main`
- Pipeline runs plan automatically
- Merge triggers production approval + apply

---

## ⚠️ Important Notes

- Never run `terraform apply` manually in production
- Always review the plan before approving
- `upgrade_settings` must be defined to avoid state drift
- Each GitHub environment needs its own federated credential

---

## 👤 Author

**subhasishmaiti16-riddhish**
