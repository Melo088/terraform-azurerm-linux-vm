# Input variables for the example.

############################################################################
# Governance variables
############################################################################

variable "client" {
  description = "Client or business unit that owns the workload."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.client))
    error_message = "The client value must be 1 to 10 lowercase alphanumeric characters."
  }
}

variable "project" {
  description = "Project the workload belongs to."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,15}$", var.project))
    error_message = "The project value must be 1 to 15 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "The environment value must be one of dev, qa or pdn."
  }
}

############################################################################
# Subscription and placement
############################################################################

variable "subscription_id" {
  description = "Azure subscription ID that receives the deployment. Supplied through the ARM_SUBSCRIPTION_ID or TF_VAR_subscription_id environment variable."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "The subscription_id must be a valid GUID."
  }
}

variable "location" {
  description = "Azure region short name that hosts the deployment."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,40}$", var.location))
    error_message = "The location must be an Azure region short name in lowercase, for example mexicocentral."
  }
}

############################################################################
# Tagging
############################################################################

variable "common_tags" {
  description = "Cross cutting governance tags applied to every resource of the example."
  type        = map(string)

  validation {
    condition     = length(setsubtract(["Client", "Project", "Environment", "Owner", "CostCenter"], keys(var.common_tags))) == 0
    error_message = "The common_tags map must define the keys Client, Project, Environment, Owner and CostCenter."
  }
}

############################################################################
# Secrets
############################################################################

variable "admin_password" {
  description = "Password of the local administrator account. Injected through the TF_VAR_admin_password environment variable and never written to a tfvars file."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12 && length(var.admin_password) <= 72
    error_message = "The admin_password must be between 12 and 72 characters."
  }

  validation {
    condition = length([
      for pattern in ["[a-z]", "[A-Z]", "[0-9]", "[^a-zA-Z0-9]"] :
      pattern if can(regex(pattern, var.admin_password))
    ]) >= 3
    error_message = "The admin_password must contain at least three of the following, a lowercase letter, an uppercase letter, a digit and a special character."
  }
}

############################################################################
# Network prerequisites
############################################################################

variable "network" {
  description = "Address plan of the virtual network and the subnet that host the virtual machine."
  type = object({
    address_space           = list(string)
    subnet_address_prefixes = list(string)
  })

  validation {
    condition     = length(var.network.address_space) > 0 && length(var.network.subnet_address_prefixes) > 0
    error_message = "Both address_space and subnet_address_prefixes must contain at least one CIDR block."
  }

  validation {
    condition = alltrue([
      for cidr in concat(var.network.address_space, var.network.subnet_address_prefixes) :
      can(cidrhost(cidr, 0))
    ])
    error_message = "Every entry of address_space and subnet_address_prefixes must be a valid CIDR block."
  }
}

variable "network_security_rules" {
  description = "Inbound and outbound rules applied to the network security group of the subnet."
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefixes    = list(string)
    destination_address_prefix = string
    description                = string
  }))

  validation {
    condition = alltrue([
      for key, rule in var.network_security_rules :
      rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "Every rule priority must be between 100 and 4096."
  }

  validation {
    condition = alltrue([
      for key, rule in var.network_security_rules :
      contains(["Inbound", "Outbound"], rule.direction) && contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "Every rule direction must be Inbound or Outbound and every access must be Allow or Deny."
  }

  validation {
    condition = alltrue([
      for key, rule in var.network_security_rules :
      contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], rule.protocol)
    ])
    error_message = "Every rule protocol must be one of Tcp, Udp, Icmp, Esp, Ah or the wildcard."
  }

  validation {
    condition = alltrue([
      for key, rule in var.network_security_rules :
      length(rule.source_address_prefixes) > 0
    ])
    error_message = "Every rule must declare at least one source address prefix."
  }
}

############################################################################
# Workload configuration
############################################################################

variable "virtual_machines" {
  description = "Base configuration of the virtual machines. Physical names and the subnet ID are injected in locals.tf."

  type = map(object({
    subnet_id      = string
    size           = string
    admin_username = string

    zone                         = optional(string)
    os_disk_caching              = optional(string, "ReadWrite")
    os_disk_storage_account_type = optional(string, "StandardSSD_LRS")
    os_disk_size_gb              = optional(number, 30)
    public_ip_sku                = optional(string, "Standard")
    public_ip_allocation_method  = optional(string, "Static")
    encryption_at_host_enabled   = optional(bool, false)
    accelerated_networking       = optional(bool, false)

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    additional_tags = optional(map(string), {})
  }))

  validation {
    condition     = length(var.virtual_machines) > 0
    error_message = "At least one virtual machine must be declared."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      can(regex("^[a-z0-9]{1,20}$", key))
    ])
    error_message = "Every map key must be 1 to 20 lowercase alphanumeric characters, it becomes the {key} component of the resource naming pattern."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      can(regex("^Standard_[A-Za-z0-9_-]+$", config.size))
    ])
    error_message = "Every size must be an Azure virtual machine size name, for example Standard_B2ls_v2."
  }
}
