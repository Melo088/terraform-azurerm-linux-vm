# Outputs.
# Each one exposes a single value, no full resource object is returned.

output "virtual_machine_ids" {
  description = "Map of virtual machine keys to the Azure resource ID of each virtual machine."
  value       = { for key, vm in azurerm_linux_virtual_machine.this : key => vm.id }
}

output "virtual_machine_names" {
  description = "Map of virtual machine keys to the physical name of each virtual machine."
  value       = { for key, vm in azurerm_linux_virtual_machine.this : key => vm.name }
}

output "admin_usernames" {
  description = "Map of virtual machine keys to the local administrator account name of each virtual machine."
  value       = { for key, vm in azurerm_linux_virtual_machine.this : key => vm.admin_username }
}

output "public_ip_addresses" {
  description = "Map of virtual machine keys to the public IPv4 address reachable over SSH."
  value       = { for key, pip in azurerm_public_ip.this : key => pip.ip_address }
}

output "private_ip_addresses" {
  description = "Map of virtual machine keys to the private IPv4 address inside the subnet."
  value       = { for key, nic in azurerm_network_interface.this : key => nic.private_ip_address }
}

output "network_interface_ids" {
  description = "Map of virtual machine keys to the Azure resource ID of each network interface."
  value       = { for key, nic in azurerm_network_interface.this : key => nic.id }
}

output "public_ip_ids" {
  description = "Map of virtual machine keys to the Azure resource ID of each public IP."
  value       = { for key, pip in azurerm_public_ip.this : key => pip.id }
}

output "ssh_commands" {
  description = "Map of virtual machine keys to the ready to run SSH command. The password is requested interactively and is never part of the output."
  value = {
    for key, vm in azurerm_linux_virtual_machine.this :
    key => "ssh ${vm.admin_username}@${azurerm_public_ip.this[key].ip_address}"
  }
}
