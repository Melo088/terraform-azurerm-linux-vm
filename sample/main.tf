# Module invocation.
# This file holds the module block and nothing else, the transformations that
# feed it live in locals.tf.

module "linux_virtual_machines" {
  # Source
  source = "../"

  # Provider injection
  providers = {
    azurerm.project = azurerm.principal
  }

  # Governance, drives naming and tagging
  client      = var.client
  project     = var.project
  environment = var.environment
  common_tags = var.common_tags

  # Placement
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  # Workload configuration
  virtual_machines = local.virtual_machines_transformed
  admin_password   = var.admin_password
}
