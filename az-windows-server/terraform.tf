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



output "suffix" {
  value = local.suffix
}

output "resource_group_name" {
  value = azurerm_resource_group.demo.name
}

output "resource_group_id" {
  value = azurerm_resource_group.demo.id
}

output "public_ip_server" {
  value = var.enable_compute ? azurerm_public_ip.server[0].ip_address : null
}

output "public_ip_client" {
  value = var.enable_compute ? azurerm_public_ip.client[0].ip_address : null
}

