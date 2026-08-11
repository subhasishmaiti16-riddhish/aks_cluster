# Azure Kubernetes Service (AKS) using Terraform

This project provisions an **Azure Kubernetes Service (AKS) cluster using Terraform** with an existing Azure VNet and Subnet.

## Architecture

```text
Azure Resource Group
        |
        +---- VNet
        |      |
        |      +---- AKS Subnet
        |              |
        |              +---- AKS Cluster
        |                      |
        |                      +---- System Node Pool
        |                      +---- Kubernetes Services
        |
        +---- AKS Managed Identity
```

## Features

* Azure Kubernetes Service (AKS)
* Terraform Infrastructure as Code
* Terraform `for_each` for AKS configuration
* Existing VNet and Subnet integration
* Azure CNI networking
* Custom Kubernetes Service CIDR
* System Assigned Managed Identity
* Sensitive kubeconfig outputs
* Reusable Terraform module structure

## Prerequisites

Make sure the following are installed and configured:

* Azure CLI
* Terraform
* An active Azure Subscription
* Required Azure permissions
* Existing Resource Group
* Existing VNet
* Existing AKS Subnet

Login to Azure:

```bash
az login
```

Verify the subscription:

```bash
az account show
```

If multiple subscriptions are available:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
```

## Project Structure

```text
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
│
└── environment/
    └── aks/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## AKS Configuration

Example configuration:

```hcl
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

Here:

* `aks1` → `for_each` key
* `aks_name` → Actual AKS cluster name
* `location` → Azure region
* `rg_name` → Resource Group
* `subnet_name` → Existing AKS subnet
* `vnet_name` → Existing VNet

## AKS Resource

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  for_each = var.aks

  name                = each.value.aks_name
  location            = each.value.location
  resource_group_name = each.value.rg_name
  dns_prefix          = "subhasish1"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v5"
    vnet_subnet_id = data.azurerm_subnet.subnet_data[each.key].id
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

## Network Design

The AKS cluster uses an existing VNet and Subnet.

Example:

```text
VNet
10.0.0.0/16
    |
    +-- AKS Subnet
        10.0.1.0/24
```

The Kubernetes Service CIDR is kept separate:

```text
Service CIDR
10.1.0.0/16

DNS Service IP
10.1.0.10
```

The Service CIDR must not overlap with the Azure VNet or AKS subnet CIDR.

## Managed Identity

The cluster uses a System Assigned Managed Identity:

```hcl
identity {
  type = "SystemAssigned"
}
```

Azure automatically creates the managed identity when the AKS cluster is provisioned.

## Initialize Terraform

```bash
terraform init
```

## Format Terraform

```bash
terraform fmt -recursive
```

## Validate Configuration

```bash
terraform validate
```

## Create Execution Plan

```bash
terraform plan
```

## Deploy AKS

```bash
terraform apply
```

To automatically approve:

```bash
terraform apply -auto-approve
```

## Verify AKS

After deployment:

```bash
az aks show \
  --resource-group rg-aks \
  --name aks-cluser \
  --output table
```

Get AKS credentials:

```bash
az aks get-credentials \
  --resource-group rg-aks \
  --name aks-cluser
```

Verify the cluster:

```bash
kubectl get nodes
```

Check all resources:

```bash
kubectl get all
```

## Terraform Outputs

The project exposes the AKS client certificate and kubeconfig as sensitive outputs.

```hcl
output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks["aks1"].kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks["aks1"].kube_config_raw
  sensitive = true
}
```

View sensitive output:

```bash
terraform output kube_config
```

## Important Notes

### Public IP

A separate `azurerm_public_ip` resource is **not required** just to create the AKS cluster.

Public IP requirements depend on how applications are exposed, such as:

* LoadBalancer Service
* Ingress
* Application Gateway

### Service CIDR

Do not use a Service CIDR that overlaps with the VNet or AKS subnet.

For example:

```text
VNet:          10.0.0.0/16
AKS Subnet:    10.0.1.0/24
Service CIDR:  10.1.0.0/16
```

### VM Size

Make sure the selected VM SKU is available in the target Azure region and subscription.

Example:

```hcl
vm_size = "Standard_D2_v5"
```

## Destroy Infrastructure

To remove the Terraform-managed AKS resources:

```bash
terraform destroy
```

Review the plan carefully before confirming the destroy operation.

## Git Workflow

Create a feature branch:

```bash
git checkout -b feature/aks-terraform
```

Check changes:

```bash
git status
```

Add files:

```bash
git add .
```

Commit:

```bash
git commit -m "Add AKS cluster using Terraform"
```

Push:

```bash
git push origin feature/aks-terraform
```

## Useful Commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
terraform destroy

az account show
az aks show --resource-group rg-aks --name aks-cluser
az aks get-credentials --resource-group rg-aks --name aks-cluser

kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

## Author

**Subhasis Maity**

DevSecOps / Cloud Infrastructure
