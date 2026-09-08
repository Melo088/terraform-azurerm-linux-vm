# Automated tests.
# The provider is mocked, so the suite runs offline and creates nothing.

mock_provider "azurerm" {
  alias = "principal"
}

variables {
  client      = "icesi"
  project     = "easyvm"
  environment = "dev"

  location            = "mexicocentral"
  resource_group_name = "icesi-easyvm-dev-rg-main"
  admin_password      = "Pl4ts2-Example-Pwd!"

  common_tags = {
    Client      = "icesi"
    Project     = "easyvm"
    Environment = "dev"
    Owner       = "juan-camilo-melo"
    CostCenter  = "plats2-lab"
  }

  virtual_machines = {
    main = {
      name                   = "icesi-easyvm-dev-vm-main"
      network_interface_name = "icesi-easyvm-dev-nic-main"
      public_ip_name         = "icesi-easyvm-dev-pip-main"
      os_disk_name           = "icesi-easyvm-dev-disk-main"
      subnet_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/icesi-easyvm-dev-rg-main/providers/Microsoft.Network/virtualNetworks/icesi-easyvm-dev-vnet-main/subnets/icesi-easyvm-dev-snet-main"
      size                   = "Standard_B2ls_v2"
      admin_username         = "azureops"

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
}

run "creates_the_expected_resource_set" {
  command = plan

  providers = {
    azurerm.project = azurerm.principal
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["main"].name == "icesi-easyvm-dev-vm-main"
    error_message = "The virtual machine must consume the name built by the root, without rebuilding it."
  }

  assert {
    condition     = azurerm_public_ip.this["main"].sku == "Standard" && azurerm_public_ip.this["main"].allocation_method == "Static"
    error_message = "The public IP must use the Standard SKU with Static allocation, the Basic SKU is retired."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["main"].disable_password_authentication == false
    error_message = "Password authentication must stay enabled, it is the access method this module exposes."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["main"].os_disk[0].storage_account_type == "StandardSSD_LRS"
    error_message = "The operating system disk must default to StandardSSD_LRS."
  }
}

run "applies_both_tag_layers" {
  command = plan

  providers = {
    azurerm.project = azurerm.principal
  }

  assert {
    condition = alltrue([
      for tag in ["Client", "Project", "Environment", "Owner", "CostCenter"] :
      contains(keys(azurerm_linux_virtual_machine.this["main"].tags), tag)
    ])
    error_message = "Every cross cutting governance tag must reach the virtual machine."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["main"].tags["Name"] == "icesi-easyvm-dev-vm-main"
    error_message = "The Name tag must be applied explicitly and must match the physical name."
  }

  assert {
    condition     = azurerm_public_ip.this["main"].tags["Role"] == "ssh-demo"
    error_message = "Caller supplied additional_tags must be merged into every resource."
  }

  assert {
    condition     = azurerm_network_interface.this["main"].tags["module"] == "terraform-azurerm-linux-vm"
    error_message = "Module metadata tags must be present on every resource."
  }
}

run "rejects_a_weak_password" {
  command = plan

  providers = {
    azurerm.project = azurerm.principal
  }

  variables {
    admin_password = "short"
  }

  expect_failures = [var.admin_password]
}

run "rejects_a_reserved_administrator_name" {
  command = plan

  providers = {
    azurerm.project = azurerm.principal
  }

  variables {
    virtual_machines = {
      main = {
        name                   = "icesi-easyvm-dev-vm-main"
        network_interface_name = "icesi-easyvm-dev-nic-main"
        public_ip_name         = "icesi-easyvm-dev-pip-main"
        os_disk_name           = "icesi-easyvm-dev-disk-main"
        subnet_id              = "/subscriptions/id/subnet"
        size                   = "Standard_B2ls_v2"
        admin_username         = "admin"

        source_image_reference = {
          publisher = "Canonical"
          offer     = "ubuntu-24_04-lts"
          sku       = "server"
          version   = "latest"
        }
      }
    }
  }

  expect_failures = [var.virtual_machines]
}

run "rejects_a_name_longer_than_the_standard" {
  command = plan

  providers = {
    azurerm.project = azurerm.principal
  }

  variables {
    virtual_machines = {
      main = {
        name                   = "icesi-easyvm-development-vm-main-oversized"
        network_interface_name = "icesi-easyvm-dev-nic-main"
        public_ip_name         = "icesi-easyvm-dev-pip-main"
        os_disk_name           = "icesi-easyvm-dev-disk-main"
        subnet_id              = "/subscriptions/id/subnet"
        size                   = "Standard_B2ls_v2"
        admin_username         = "azureops"

        source_image_reference = {
          publisher = "Canonical"
          offer     = "ubuntu-24_04-lts"
          sku       = "server"
          version   = "latest"
        }
      }
    }
  }

  expect_failures = [var.virtual_machines]
}

run "rejects_incomplete_governance_tags" {
  command = plan

  providers = {
    azurerm.project = azurerm.principal
  }

  variables {
    common_tags = {
      Client  = "icesi"
      Project = "easyvm"
    }
  }

  expect_failures = [var.common_tags]
}

run "rejects_an_empty_subnet_id" {
  command = plan

  providers = {
    azurerm.project = azurerm.principal
  }

  variables {
    virtual_machines = {
      main = {
        name                   = "icesi-easyvm-dev-vm-main"
        network_interface_name = "icesi-easyvm-dev-nic-main"
        public_ip_name         = "icesi-easyvm-dev-pip-main"
        os_disk_name           = "icesi-easyvm-dev-disk-main"
        subnet_id              = ""
        size                   = "Standard_B2ls_v2"
        admin_username         = "azureops"

        source_image_reference = {
          publisher = "Canonical"
          offer     = "ubuntu-24_04-lts"
          sku       = "server"
          version   = "latest"
        }
      }
    }
  }

  expect_failures = [var.virtual_machines]
}

run "rejects_names_outside_the_governance_prefix" {
  command = plan

  providers = {
    azurerm.project = azurerm.principal
  }

  variables {
    virtual_machines = {
      main = {
        name                   = "other-workload-vm-main"
        network_interface_name = "icesi-easyvm-dev-nic-main"
        public_ip_name         = "icesi-easyvm-dev-pip-main"
        os_disk_name           = "icesi-easyvm-dev-disk-main"
        subnet_id              = "/subscriptions/id/subnet"
        size                   = "Standard_B2ls_v2"
        admin_username         = "azureops"

        source_image_reference = {
          publisher = "Canonical"
          offer     = "ubuntu-24_04-lts"
          sku       = "server"
          version   = "latest"
        }
      }
    }
  }

  expect_failures = [var.virtual_machines]
}
