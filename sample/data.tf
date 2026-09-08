# Data sources.

# Records which subscription produced the deployment, exposed through
# outputs.tf so the run can be traced back.
data "azurerm_client_config" "current" {
  provider = azurerm.principal
}
