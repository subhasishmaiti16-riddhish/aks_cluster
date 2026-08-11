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

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks["aks1"].kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks["aks1"].kube_config_raw

  sensitive = true
}
######## OR ########

# output "kube_config" {
#   value = {
#     for key, cluster in azurerm_kubernetes_cluster.aks :
#     key => cluster.kube_config_raw
#   }

#   sensitive = true
# }

# aks1                         aks-cluser
#  ↓                              ↓
# KEY                            VALUE
#  ↓                              ↓
# Terraform-এর reference       Azure AKS-এর actual name
