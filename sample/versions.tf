# Terraform and provider version requirements for the example.
#
# State is kept locally because this is a demonstration. A shared environment
# would declare an azurerm backend backed by a storage account.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.4"
    }
  }
}
