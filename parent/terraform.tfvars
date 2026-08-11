rg_parent = {
  rg1 = {
    rg_name  = "rg-aks"
    location = "central india"
  }
}

vnet_parent = {
  vnet1 = {
    vnet_name     = "vnet-aks"
    rg_name       = "rg-aks"
    location      = "central india"
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
    location    = "central india"
    rg_name     = "rg-aks"
    subnet_name = "subnet-aks-node"
    vnet_name   = "vnet-aks"
  }
}