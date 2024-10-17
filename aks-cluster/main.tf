provider "azurerm" {
  features {}

  skip_provider_registration = true
}

# Declare the Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "t2s_services_rg"
  location = var.location
}

# Virtual Network and Subnet (you might already have these)
# Virtual Network Definition
resource "azurerm_virtual_network" "vnet" {
  name                = "t2s_services_vnet"
  address_space       = ["10.0.0.0/16"]  # The virtual network's address space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet Definition
resource "azurerm_subnet" "subnet" {
  name                 = "t2s_services_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]  # Ensure this is within the VNet's address space (10.0.0.0/16)
}

# Azure Kubernetes Service (AKS) Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "t2s-services-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "t2s-services"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    service_cidr      = "10.1.0.0/16"   # Use a CIDR block that does not overlap with your VNet or subnet
    dns_service_ip    = "10.1.0.10"     # Ensure this is within the service_cidr range
    docker_bridge_cidr = "172.17.0.1/16"
  }
}

# Azure Network Security Group (NSG)
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Role Assignments for AKS Identity
resource "azurerm_role_assignment" "aks_identity_role" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.rg.id
}

resource "azurerm_role_assignment" "csi_driver_role" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.rg.id
}
