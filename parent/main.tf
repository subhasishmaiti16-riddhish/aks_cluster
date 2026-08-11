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