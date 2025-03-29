# terraform.tf

# Configure the Azure provider (optional, if you need Azure resources for additional context)
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">= 0.1.0"
    }
  }
}

# Variables
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure Location"
  type        = string
}

variable "vm_username" {
  description = "VM Username"
  type        = string
}

variable "enable_compute" {
  description = "Enable Compute"
  type        = bool
  default     = true
}

# Generate a random suffix
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  suffix = random_string.suffix.result
}

# Resource Group
resource "azurerm_resource_group" "demo" {
  name     = "kasm-workspace-demo-${local.suffix}"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "demo" {
  name                = "kasm-workspace-demo-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "demo" {
  name                 = "kasm-workspace-demo-${local.suffix}"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Public IP
resource "azurerm_public_ip" "demo" {
  count               = var.enable_compute ? 1 : 0
  name                = "kasm-workspace-demo-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name
  allocation_method   = "Static"
}

# Network Interface
resource "azurerm_network_interface" "demo" {
  count               = var.enable_compute ? 1 : 0
  name                = "kasm-workspace-demo-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "kasm-workspace-demo-${local.suffix}"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_compute ? azurerm_public_ip.demo[0].id : null
  }
}

# Network Security Group
resource "azurerm_network_security_group" "demo" {
  name                = "kasm-workspace-demo"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "Allow_SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Kasm"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4902"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface Security Group Association
resource "azurerm_network_interface_security_group_association" "demo" {
  count                 = var.enable_compute ? 1 : 0
  network_interface_id      = azurerm_network_interface.demo[0].id
  network_security_group_id = azurerm_network_security_group.demo.id
}

# Replace with Ubuntu VM
resource "azurerm_linux_virtual_machine" "demo_vm" {
  count                 = var.enable_compute ? 1 : 0
  name                  = "demo-vm"
  resource_group_name   = azurerm_resource_group.demo.name
  location              = azurerm_resource_group.demo.location
  size                  = "Standard_B2s"
  admin_username        = var.vm_username
  
  admin_ssh_key {
    username   = var.vm_username
    public_key = file("~/.ssh/id_rsa_kasm.pub")
  }

  network_interface_ids = var.enable_compute ? [azurerm_network_interface.demo[0].id] : []

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  # source_image_reference {
  #   publisher = "Canonical"
  #   offer     = "0001-com-ubuntu-server-jammy"
  #   sku       = "22_04-lts-gen2"
  #   version   = "latest"
  # }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"  # or "20.04-LTS" if you prefer newer version
    version   = "latest"
  }

  # Optional: Add custom data for bootstrap script
  # custom_data = base64encode(file("bootstrap.sh"))
}

output "suffix" {
  value = local.suffix
}

output "resource_group_name" {
  value = azurerm_resource_group.demo.name
}

output "resource_group_id" {
  value = azurerm_resource_group.demo.id
}

output "public_ip" {
  value = var.enable_compute ? azurerm_public_ip.demo[0].ip_address : null
}

