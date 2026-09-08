# Concrete values for the example.
# No secret is stored here. The administrator password and the subscription ID
# arrive through environment variables at run time.

############################################################################
# Governance
############################################################################

client      = "icesi"
project     = "easyvm"
environment = "dev"

location = "mexicocentral"

common_tags = {
  Client      = "icesi"
  Project     = "easyvm"
  Environment = "dev"
  Owner       = "juan-camilo-melo"
  CostCenter  = "plats2-lab"
}

############################################################################
# Network prerequisites
############################################################################

network = {
  address_space           = ["10.42.0.0/16"]
  subnet_address_prefixes = ["10.42.1.0/24"]
}

network_security_rules = {
  ssh = {
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
    description                = "Public SSH access. Narrow this prefix to the operator network outside a lab."
  }
}

############################################################################
# Workload
############################################################################

virtual_machines = {
  main = {
    # Left empty on purpose, locals.tf fills it with the ID of the subnet
    # created by this example.
    subnet_id = ""

    # Burstable size available in mexicocentral outside availability zone 1.
    size           = "Standard_B2ls_v2"
    admin_username = "azureops"

    os_disk_storage_account_type = "StandardSSD_LRS"
    os_disk_size_gb              = 30

    source_image_reference = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      version   = "latest"
    }

    additional_tags = {
      Role = "ssh-demo"
    }
  }
}
