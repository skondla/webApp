
variable "TF_VAR_ARM_CLIENT_ID" {}
variable "TF_VAR_ARM_CLIENT_SECRET" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=1.28.0"
    }
  }
}

provider "azurerm" {}

resource "azurerm_resource_group" "rg" {
  name     = "test"
  location = "eastus2"
}
resource "azurerm_virtual_network" "network" {
  name                = "aks-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                      = "aks-subnet"
  resource_group_name       = azurerm_resource_group.rg.name
  address_prefixes          = ["10.1.0.0/24"]
  virtual_network_name      = azurerm_virtual_network.network.name
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name       = "aks"
  location   = azurerm_resource_group.rg.location
  dns_prefix = "aks"

  resource_group_name = azurerm_resource_group.rg.name
  kubernetes_version  = "1.32"

  default_node_pool {
    name           = "aks"
    node_count     = 1
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.subnet.id
  }

  service_principal {
    client_id     = var.TF_VAR_ARM_CLIENT_ID
    client_secret = var.TF_VAR_ARM_CLIENT_SECRET
  }

  network_profile {
    network_plugin = "azure"
  }
}