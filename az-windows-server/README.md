# Azure Windows Server

> *A Kasm Workspace server installed on a Windows Server hosted in Azure Cloud.*

## General Requirements
The requirement is to add Kasm to a Windows server, technically on their onprem VMware ESXi virtual machine. I'm not as familiar with ESXi, so my plan is to test, document and possibly automate the setup in a familiar environment. That way I can reproduce it quickly on their infrastructure and know that anything that goes wrong is not related to my understanding of how to get Kasm working, but related to nuances in their infrastructure architecture or server configuration.

### Additional Benefits
Another benefit of this is that if I run out of time and I don't have a demo ready (God forbid) by next week, I can offer to present a demo on my own infrastructure. Having it automated makes it practical to tear down to save cost and fire up to have it available.

### Ideal Outcome
The best possible outcome is that I can get it working on my own Windows server and then quickly port it over to their server to demo next week.

## Vision in Broad Strokes


### Core Components
- A Windows server VM in Azure with a public IP and Remote Desktop access.
- A VPN for connecting to the server. Probably Pritunl (unless that install is weird on Windows but I think it's fine).
- Kasm Workspaces server. (Single instance control plane for now but start docs on high-availability clusters and elastic infrastructure)
- Whatever trust certificates we need to establish HTTPS between the user browser and the Kasm Server.

That should cover all of the basic components.

### Other Questions and Concerns
- I'd like to plug the authentication for this into EntraID and set up some test users with basic auth that they can use temporarily for a demo and just disable MFA/SSO for this particular group. That way everyone can log in instantly and get started but feel assured that since it's using Active Directory, they can plug in all of their familiar trusted identity and access management capabilities like SSO and MFA all managed my Microsoft. 
- Find out 


## Infrastructure

An Azure VM running Windows server with the minimum basic infrastructure to connect to the machine with RDP and get started.

```hcl
# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Reference your existing resource group
resource "azurerm_resource_group" "existing" {
  name     = "your-existing-resource-group"  # Replace with your resource group name
  location = "eastus3"                      # Using East US 3 as per your earlier question
}

# Create a Virtual Network
resource "azurerm_virtual_network" "demo_vnet" {
  name                = "demo-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.existing.location
  resource_group_name = azurerm_resource_group.existing.name
}

# Create a Subnet
resource "azurerm_subnet" "demo_subnet" {
  name                 = "demo-subnet"
  resource_group_name  = azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.demo_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a Public IP
resource "azurerm_public_ip" "demo_public_ip" {
  name                = "demo-public-ip"
  location            = azurerm_resource_group.existing.location
  resource_group_name = azurerm_resource_group.existing.name
  allocation_method   = "Dynamic"  # Dynamic for simplicity; use Static if you need a fixed IP
}

# Create a Network Security Group (NSG) with RDP rule
resource "azurerm_network_security_group" "demo_nsg" {
  name                = "demo-nsg"
  location            = azurerm_resource_group.existin.location
  resource_group_name = azurerm_resource_group.existing.name

  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"  # RDP port
    source_address_prefix      = "*"     # Warning: This allows RDP from any IP; restrict in production
    destination_address_prefix = "*"
  }
}

# Create a Network Interface
resource "azurerm_network_interface" "demo_nic" {
  name                = "demo-nic"
  location            = azurerm_resource_group.existing.location
  resource_group_name = azurerm_resource_group.existing.name

  ip_configuration {
    name                          = "demo-ipconfig"
    subnet_id                     = azurerm_subnet.demo_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_public_ip.id
  }
}

# Associate the NSG with the Network Interface
resource "azurerm_network_interface_security_group_association" "demo_nic_nsg" {
  network_interface_id      = azurerm_network_interface.demo_nic.id
  network_security_group_id = azurerm_network_security_group.demo_nsg.id
}

# Create a Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "demo_vm" {
  name                  = "demo-vm"
  resource_group_name   = azurerm_resource_group.existing.name
  location              = azurerm_resource_group.existing.location
  size                  = "Standard_B2s"  # Small, cost-effective size for demo
  admin_username        = "adminuser"     # Replace with your preferred username
  admin_password        = "P@ssw0rd1234!" # Replace with a strong password
  network_interface_ids = [azurerm_network_interface.demo_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"  # Cheapest option for demo
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"  # Windows Server 2019; adjust as needed
    version   = "latest"
  }
}

# Output the Public IP to connect via RDP
output "public_ip_address" {
  value = azurerm_public_ip.demo_public_ip.ip_address
}
```

### Installation on Ubuntu

```
cd /tmp
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.16.1.98d6fa.tar.gz
tar -xf kasm_release_1.16.1.98d6fa.tar.gz
```

There seem to be issues with allocating the swap file. I had to do it manually before running the install.
```
# Create swap file using dd instead of fallocate
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192   # This creates an 8GB swap file

# Set correct permissions
sudo chmod 600 /swapfile

# Set up the swap file
sudo mkswap /swapfile

# Enable the swap
sudo swapon /swapfile

# Make it permanent by adding to fstab
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

Now Install
```
sudo bash kasm_release/install.sh
```
