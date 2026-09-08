# Network scaffolding that hosts the virtual machine.
#
# These resources live here rather than inside the module so the module stays
# reusable across any existing network. Keeping them in the example also means a
# single terraform apply produces a working environment.

resource "azurerm_resource_group" "this" {
  provider = azurerm.principal

  name     = local.resource_group_name
  location = var.location

  tags = merge(var.common_tags, { Name = local.resource_group_name })
}

resource "azurerm_virtual_network" "this" {
  provider = azurerm.principal

  name                = local.virtual_network_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = var.network.address_space

  tags = merge(var.common_tags, { Name = local.virtual_network_name })
}

resource "azurerm_subnet" "this" {
  provider = azurerm.principal

  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.network.subnet_address_prefixes

  # Azure is retiring implicit outbound internet access. The virtual machine
  # egresses through its own public IP, so the implicit path is turned off.
  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "this" {
  provider = azurerm.principal

  name                = local.network_security_group_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = merge(var.common_tags, { Name = local.network_security_group_name })
}

resource "azurerm_network_security_rule" "this" {
  provider = azurerm.principal
  for_each = var.network_security_rules

  name                        = local.network_security_rule_names[each.key]
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name

  priority                   = each.value.priority
  direction                  = each.value.direction
  access                     = each.value.access
  protocol                   = each.value.protocol
  source_port_range          = each.value.source_port_range
  destination_port_range     = each.value.destination_port_range
  source_address_prefixes    = each.value.source_address_prefixes
  destination_address_prefix = each.value.destination_address_prefix
  description                = each.value.description
}

resource "azurerm_subnet_network_security_group_association" "this" {
  provider = azurerm.principal

  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id

  depends_on = [azurerm_network_security_rule.this]
}
