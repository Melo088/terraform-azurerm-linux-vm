# Local values and transformations.
#
# Physical resource names arrive already built from the caller, so this block
# only resolves the tags applied to every managed resource.

locals {
  # Metadata attached to everything this module creates.
  base_module_tags = {
    "managed-by" = "terraform"
    "module"     = "terraform-azurerm-linux-vm"
  }

  # Governance tags shared by every resource.
  shared_tags = merge(var.common_tags, local.base_module_tags)

  # Per resource tags, an explicit Name plus anything the caller adds.
  virtual_machine_tags = {
    for key, config in var.virtual_machines : key => merge(
      local.shared_tags,
      { Name = config.name },
      config.additional_tags,
    )
  }

  network_interface_tags = {
    for key, config in var.virtual_machines : key => merge(
      local.shared_tags,
      { Name = config.network_interface_name },
      config.additional_tags,
    )
  }

  public_ip_tags = {
    for key, config in var.virtual_machines : key => merge(
      local.shared_tags,
      { Name = config.public_ip_name },
      config.additional_tags,
    )
  }
}
