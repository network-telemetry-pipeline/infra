# Infrastructure setup

## Terraform - provision VMs

Run following commands to plan and provision 3 VMs in GCP:
```
terraform plan
terraform apply
```

This will output inventory.ini file for Ansible where the information of how to deploy to VMs will be stored.

## Ansible - create Kubernetes cluster and install CNI

Then, run:

```
ansible-playbook site.yml
```

## Destroy infrastructure

When finished, destroy the whole infrastructure:
```
terraform destroy
```
