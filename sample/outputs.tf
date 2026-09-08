# Outputs.

output "subscription_id" {
  description = "Azure subscription that received the deployment."
  value       = data.azurerm_client_config.current.subscription_id
}

output "resource_group_name" {
  description = "Name of the resource group that groups every resource of the example."
  value       = azurerm_resource_group.this.name
}

output "subnet_id" {
  description = "Azure resource ID of the subnet that hosts the virtual machine."
  value       = azurerm_subnet.this.id
}

output "virtual_machine_names" {
  description = "Map of virtual machine keys to the physical name of each virtual machine."
  value       = module.linux_virtual_machines.virtual_machine_names
}

output "public_ip_addresses" {
  description = "Map of virtual machine keys to the public IPv4 address reachable over SSH."
  value       = module.linux_virtual_machines.public_ip_addresses
}

output "private_ip_addresses" {
  description = "Map of virtual machine keys to the private IPv4 address inside the subnet."
  value       = module.linux_virtual_machines.private_ip_addresses
}

output "ssh_commands" {
  description = "Map of virtual machine keys to the ready to run SSH command."
  value       = module.linux_virtual_machines.ssh_commands
}
