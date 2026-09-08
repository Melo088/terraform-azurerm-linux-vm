# Terraform and provider version requirements.
# No backend is declared here, the state belongs to the root configuration that
# consumes this module.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.0, < 6.0.0"

      # The configured provider is injected by the caller.
      configuration_aliases = [azurerm.project]
    }
  }
}
