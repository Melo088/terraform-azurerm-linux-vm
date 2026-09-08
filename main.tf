# Resources managed by this module.
#
# The scope is limited to what a virtual machine needs to exist and be
# reachable. The resource group, virtual network, subnet and network security
# group are owned by the caller and arrive as inputs.

############################################################################
# Public IP
############################################################################

resource "azurerm_public_ip" "this" {
  provider = azurerm.project
  for_each = var.virtual_machines

  name                = each.value.public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location

  # The Basic SKU reached end of life on 30 September 2025. Standard plus Static
  # is the only supported combination.
  sku               = each.value.public_ip_sku
  allocation_method = each.value.public_ip_allocation_method

  # The address is only pinned to a zone when the virtual machine itself is
  # zonal, otherwise it stays regional and zone redundant.
  zones = each.value.zone == null ? null : [each.value.zone]

  tags = local.public_ip_tags[each.key]
}

############################################################################
# Network interface
############################################################################

resource "azurerm_network_interface" "this" {
  # checkov:skip=CKV_AZURE_119:Public internet reachable SSH is the documented purpose of this module. The exposure is bounded by the network security group owned by the caller.
  provider = azurerm.project
  for_each = var.virtual_machines

  name                = each.value.network_interface_name
  resource_group_name = var.resource_group_name
  location            = var.location

  accelerated_networking_enabled = each.value.accelerated_networking

  ip_configuration {
    name                          = "ipconfig-primary"
    primary                       = true
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this[each.key].id
  }

  tags = local.network_interface_tags[each.key]
}

############################################################################
# Linux virtual machine
############################################################################

resource "azurerm_linux_virtual_machine" "this" {
  # checkov:skip=CKV_AZURE_1:Password authentication is the access method this module is required to expose. The credential is injected at runtime and never versioned.
  # checkov:skip=CKV_AZURE_149:Same rationale as CKV_AZURE_1.
  # checkov:skip=CKV_AZURE_178:Same rationale as CKV_AZURE_1, no SSH public key is provisioned by design.
  # checkov:skip=CKV_AZURE_50:No virtual machine extension is declared. The finding comes from allow_extension_operations resolving after apply.
  provider = azurerm.project
  for_each = var.virtual_machines

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = each.value.size
  zone                = each.value.zone

  # Password authentication is an explicit requirement here. The value is
  # injected at runtime and never stored in version control.
  admin_username                  = each.value.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.this[each.key].id]

  # Managed disks are encrypted at rest by the platform by default. Host based
  # encryption additionally covers the temporary disk and the cache, and needs
  # the Microsoft.Compute/EncryptionAtHost feature registered on the
  # subscription.
  encryption_at_host_enabled = each.value.encryption_at_host_enabled

  os_disk {
    name                 = each.value.os_disk_name
    caching              = each.value.os_disk_caching
    storage_account_type = each.value.os_disk_storage_account_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  # Serial console and screenshots through a platform managed storage account.
  boot_diagnostics {}

  tags = local.virtual_machine_tags[each.key]
}
