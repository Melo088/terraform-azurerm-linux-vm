# Deployment evidence

Screenshots that prove the deployment ran end to end. The root `README.md`
embeds these files by name, so keep the file names exactly as listed.

| File | What to capture |
| --- | --- |
| `01-terraform-plan.png` | Terminal showing the tail of `terraform plan`, with the line `Plan: 9 to add, 0 to change, 0 to destroy.` |
| `02-terraform-apply.png` | Terminal showing the tail of `terraform apply`, with `Apply complete! Resources: 9 added` and the resolved outputs |
| `03-azure-portal-resource-group.png` | Azure portal, resource group `icesi-easyvm-dev-rg-main`, listing the nine resources |
| `04-azure-portal-vm-overview.png` | Azure portal, overview blade of `icesi-easyvm-dev-vm-main`, showing status Running, region Mexico Central and the public IP address |
| `05-ssh-session.png` | Terminal with the SSH session established, showing the Ubuntu banner and the output of `hostnamectl` |
| `06-terraform-destroy.png` | Terminal showing the tail of `terraform destroy`, with `Destroy complete! Resources: 9 destroyed.` |

## Capture guidance

Crop to the terminal window or the portal blade, avoid full desktop captures.

Redact the subscription GUID and the public IP address if the repository is
going to be public. The administrator password must never appear in a
screenshot, `terraform output` never prints it.

Use PNG at a width of at least 1200 pixels so the text stays readable on
GitHub.
