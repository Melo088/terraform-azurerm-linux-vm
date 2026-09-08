# Example, public SSH virtual machine in Mexico Central

Runnable configuration that consumes the parent module and produces one Ubuntu
24.04 LTS virtual machine reachable over SSH with a local user and password.

This directory also creates the network the machine needs, so a single
`terraform apply` produces a working environment.

## What gets created

| Resource | Created by | Physical name |
| --- | --- | --- |
| `azurerm_resource_group` | example | `icesi-easyvm-dev-rg-main` |
| `azurerm_virtual_network` | example | `icesi-easyvm-dev-vnet-main` |
| `azurerm_subnet` | example | `icesi-easyvm-dev-snet-main` |
| `azurerm_network_security_group` | example | `icesi-easyvm-dev-nsg-main` |
| `azurerm_network_security_rule` | example | `icesi-easyvm-dev-nsgr-ssh` |
| `azurerm_subnet_network_security_group_association` | example | association only |
| `azurerm_public_ip` | module | `icesi-easyvm-dev-pip-main` |
| `azurerm_network_interface` | module | `icesi-easyvm-dev-nic-main` |
| `azurerm_linux_virtual_machine` | module | `icesi-easyvm-dev-vm-main` |

## Run it

```bash
az login
az account set --subscription "<subscription-id>"

export TF_VAR_subscription_id="$(az account show --query id -o tsv)"
read -rsp 'Admin password: ' TF_VAR_admin_password && export TF_VAR_admin_password && echo

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Connect using the command printed by `terraform output ssh_commands`.

Tear the environment down when the exercise is finished.

```bash
terraform destroy
```

## How the configuration flows

```
terraform.tfvars -> variables.tf -> prerequisites.tf -> locals.tf -> main.tf -> ../
   base values        typing          network            naming and     module
                                                         injection      invocation
```

`terraform.tfvars` leaves `subnet_id` empty on purpose. `locals.tf` fills it with
the ID of the subnet created here and builds every physical name, so the module
receives a complete payload and never rebuilds a name itself.
