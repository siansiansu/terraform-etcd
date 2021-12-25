# terraform-etcd

This is a terraform code for deploying an etcd cluster with 3 nodes.

## Installation

```bash
git clone git@github.com:siansiansu/terraform-etcd.git
```

Preview the changes with terraform plan.

```bash
terraform plan -var-file=service/stage.tfvars
```

Apply the changes

```bash
terraform apply -var-file=service/stage.tfvars
```

## Contact Me

@alexsu <minsiansu@gmail.com>
