# A Workstation running Windows 11
resource "azurerm_public_ip" "client" {
  count               = var.enable_compute ? 1 : 0
  name                = "kasm-workspace-client-${local.suffix}"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  allocation_method   = "Static"
}

# Network Interface
resource "azurerm_network_interface" "client" {
  count               = var.enable_compute ? 1 : 0
  name                = "kasm-workspace-client-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "kasm-workspace-client-${local.suffix}"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_compute ? azurerm_public_ip.client[0].id : null
  }
}


resource "azurerm_windows_virtual_machine" "client" {
  count               = var.enable_compute ? 1 : 0
  name                = "kasm-workspace-client-${local.suffix}"
  computer_name       = "kasm-client"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  size                = "Standard_B2s"
  admin_username      = "kasmuser"
  admin_password      = "kasmuser12#"
  network_interface_ids = [azurerm_network_interface.client[0].id]
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# Network Interface Security Group Association
resource "azurerm_network_interface_security_group_association" "client" {
  count                 = var.enable_compute ? 1 : 0
  network_interface_id      = azurerm_network_interface.client[0].id
  network_security_group_id = azurerm_network_security_group.client.id
}

# Allow RDP access from the internet
resource "azurerm_network_security_group" "client" {
  name                = "kasm-workspace-client"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "Allow_RDP_Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_RDP_Outbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS_Inbound"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS_Outbound"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTP_Inbound"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTP_Outbound"
    priority                   = 1006
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow AnyDesk inbound and outbound
# AnyDesk primarily uses ports 80, 443, and 6568 for establishing connections. For direct connections, it uses port 7070 by default. Additionally, it uses UDP ports 50001-50003 for discovery on local networks. 
  
  security_rule {
    name                       = "Allow_AnyDesk_Inbound_6568"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6568"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_AnyDesk_Outbound_6568"
    priority                   = 1008
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6568"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_AnyDesk_Inbound_7070"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7070"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_AnyDesk_Outbound_7070"
    priority                   = 1010
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7070"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow anydesk udp ports
  security_rule {
    name                       = "Allow_AnyDesk_UDP_Inbound"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "50001-50003"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_AnyDesk_UDP_Outbound"
    priority                   = 1012
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "50001-50003"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # whitelist *.net.anydesk.com
  security_rule {
    name                       = "Allow_AnyDesk_DNS_Inbound"
    priority                   = 1013
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  # Allow 
  

#   security_rule {
#     name                       = "Allow_Kasm_Inbound"
#     priority                   = 1002
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "4902"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "Allow_Kasm_Outbound"
#     priority                   = 1003
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "4902"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }


}


