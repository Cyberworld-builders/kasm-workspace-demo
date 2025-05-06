# Public IP
resource "azurerm_public_ip" "server" {
  count               = var.enable_compute ? 1 : 0
  name                = "kasm-workspace-server-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name
  allocation_method   = "Static"
}

# Network Interface
resource "azurerm_network_interface" "server" {
  count               = var.enable_compute ? 1 : 0
  name                = "kasm-workspace-server-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "kasm-workspace-server-${local.suffix}"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_compute ? azurerm_public_ip.server[0].id : null
  }
}

# Network Security Group
resource "azurerm_network_security_group" "server" {
  name                = "kasm-workspace-server"
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

#   security_rule {
#     name                       = "Allow_Kasm"
#     priority                   = 1002
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "4902"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
}

# Network Interface Security Group Association
resource "azurerm_network_interface_security_group_association" "server" {
  count                 = var.enable_compute ? 1 : 0
  network_interface_id      = azurerm_network_interface.server[0].id
  network_security_group_id = azurerm_network_security_group.server.id
}

# Replace with Ubuntu VM
resource "azurerm_linux_virtual_machine" "server" {
  count                 = var.enable_compute ? 1 : 0
  name                  = "kasm-workspace-server-${local.suffix}"
  resource_group_name   = azurerm_resource_group.demo.name
  location              = azurerm_resource_group.demo.location
  size                  = "Standard_B2s"
  admin_username        = var.vm_username
  
  admin_ssh_key {
    username   = var.vm_username
    public_key = file("~/.ssh/id_rsa_kasm.pub")
  }

  network_interface_ids = var.enable_compute ? [azurerm_network_interface.server[0].id] : []

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