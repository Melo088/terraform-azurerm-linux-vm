# Provider contract.
#
# A reusable module never declares its own `provider` block. It receives the
# already configured provider from the caller through the `azurerm.project`
# alias declared in versions.tf, and every resource in main.tf references that
# alias explicitly.
