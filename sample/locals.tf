# Transformations.
#
# Every physical name is built here and injected into the configuration payload,
# so the module receives final values and never rebuilds a name itself.

locals {
  # Naming prefix shared by every resource.
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  # Names of the network prerequisites owned by this example.
  resource_group_name         = "${local.governance_prefix}-rg-main"
  virtual_network_name        = "${local.governance_prefix}-vnet-main"
  subnet_name                 = "${local.governance_prefix}-snet-main"
  network_security_group_name = "${local.governance_prefix}-nsg-main"

  network_security_rule_names = {
    for key, rule in var.network_security_rules :
    key => "${local.governance_prefix}-nsgr-${key}"
  }

  # Configuration payload consumed by the module. Names follow
  # {client}-{project}-{environment}-{type}-{key} and the subnet ID is filled in
  # from the subnet created here when the input is left empty.
  virtual_machines_transformed = {
    for key, config in var.virtual_machines : key => merge(config, {
      name                   = "${local.governance_prefix}-vm-${key}"
      network_interface_name = "${local.governance_prefix}-nic-${key}"
      public_ip_name         = "${local.governance_prefix}-pip-${key}"
      os_disk_name           = "${local.governance_prefix}-disk-${key}"
      subnet_id              = length(config.subnet_id) > 0 ? config.subnet_id : azurerm_subnet.this.id
    })
  }
}
