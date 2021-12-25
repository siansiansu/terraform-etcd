# terraform-etcd

This is a terraform code for deploying an etcd cluster with 3 nodes.

## Installation

1. Clone the repo
```bash
git clone git@github.com:siansiansu/terraform-etcd.git
```

2. Preview the changes

```bash
terraform plan -var-file=service/stage.tfvars
```

3. Apply the changes

```bash
terraform apply -var-file=service/stage.tfvars
```

## References

- [etcd.io](https://etcd.io)
- [terraform](https://www.terraform.io/)

## Contact Me

@siansiansu <minsiansu@gmail.com>
