# Input variables.
# Every variable declares an explicit type, a description and at least one
# validation block, so bad input fails at plan time instead of at apply time.

############################################################################
# Governance variables, they drive naming and tagging
############################################################################

variable "client" {
  description = "Client or business unit that owns the workload. First component of the resource naming pattern."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.client))
    error_message = "The client value must be 1 to 10 lowercase alphanumeric characters."
  }
}

variable "project" {
  description = "Project the workload belongs to. Second component of the resource naming pattern."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,15}$", var.project))
    error_message = "The project value must be 1 to 15 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Deployment environment. Third component of the resource naming pattern."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "The environment value must be one of dev, qa or pdn."
  }
}

############################################################################
# Placement variables
############################################################################

variable "location" {
  description = "Azure region short name where every resource of this module is deployed, for example mexicocentral."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,40}$", var.location))
    error_message = "The location must be an Azure region short name in lowercase, for example mexicocentral."
  }
}

variable "resource_group_name" {
  description = "Name of an existing resource group that hosts the virtual machines. The resource group is owned by the caller."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "The resource_group_name must be a non empty string of at most 90 characters."
  }
}

############################################################################
# Tagging
############################################################################

variable "common_tags" {
  description = "Cross cutting governance tags merged into every resource created by the module."
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
  description = "Password of the local administrator account of every virtual machine. Injected at runtime through the TF_VAR_admin_password environment variable, never stored in a tfvars file."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12 && length(var.admin_password) <= 72
    error_message = "The admin_password must be between 12 and 72 characters, as required by the Azure compute platform."
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
# Workload configuration
############################################################################

variable "virtual_machines" {
  description = <<-EOT
    Map of Linux virtual machines to create, keyed by the {key} component of the
    resource naming pattern. Physical names arrive already built from the
    caller, this module only consumes them.
  EOT

  type = map(object({
    name                   = string
    network_interface_name = string
    public_ip_name         = string
    os_disk_name           = string
    subnet_id              = string
    size                   = string
    admin_username         = string

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
    condition = alltrue([
      for key, config in var.virtual_machines :
      alltrue([
        for name in [config.name, config.network_interface_name, config.public_ip_name, config.os_disk_name] :
        can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", name)) && length(name) <= 28
      ])
    ])
    error_message = "Every resource name must be lowercase, hyphen separated and at most 28 characters, following the pattern {client}-{project}-{environment}-{type}-{key}."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      can(regex("^[a-z_][a-z0-9_-]{0,31}$", config.admin_username)) && !contains(
        ["admin", "administrator", "root", "guest", "test", "user", "sys", "adm", "backup", "console", "owner", "server", "sql", "support", "video"],
        config.admin_username
      )
    ])
    error_message = "The admin_username must be 1 to 32 lowercase characters and must not be one of the names reserved by the Azure compute platform."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      length(config.subnet_id) > 0
    ])
    error_message = "Every virtual machine must receive a non empty subnet_id resolved by the caller."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      contains(["None", "ReadOnly", "ReadWrite"], config.os_disk_caching)
    ])
    error_message = "The os_disk_caching value must be one of None, ReadOnly or ReadWrite."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      contains(["Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS"], config.os_disk_storage_account_type)
    ])
    error_message = "The os_disk_storage_account_type value must be one of Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_LRS or Premium_ZRS."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      config.public_ip_sku == "Standard" ? config.public_ip_allocation_method == "Static" : true
    ])
    error_message = "A Standard SKU public IP only supports the Static allocation method. The Basic SKU reached end of life on 30 September 2025 and must not be used."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      contains(["Standard"], config.public_ip_sku)
    ])
    error_message = "Only the Standard public IP SKU is allowed, the Basic SKU is retired."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      config.os_disk_size_gb >= 30 && config.os_disk_size_gb <= 4095
    ])
    error_message = "The os_disk_size_gb value must be between 30 and 4095."
  }

  validation {
    condition = alltrue([
      for key, config in var.virtual_machines :
      alltrue([for field in values(config.source_image_reference) : length(field) > 0])
    ])
    error_message = "Every field of source_image_reference must be a non empty string."
  }
}
