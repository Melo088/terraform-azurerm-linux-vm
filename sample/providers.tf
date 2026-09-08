# Provider configuration.
# Credentials come from the Azure CLI context, so no secret lives in the repo.

provider "azurerm" {
  alias = "principal"

  subscription_id = var.subscription_id

  features {}
}
