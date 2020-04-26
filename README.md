## terraform-examples

Some working Terraform examples for provisioning AWS resources.

* loadbalanced-ec2 -  auto scaled internet facing EC2 app
* loadbalanced-ecs -  auto scaled internet facing ECS app
* privatelink -  2 VPCs with VPC endpoint connection
* single-public -  single VPC with 1 public subnet
* single-public-single-private - single VPC with 1 public and 1 private subnet


## Running
Ensure:
* You have configured your AWS credentials with appropriate permission to the AWS resources (EC2, ECS, IAM, VPC)
* You have Terraform installed, (Mac OSX: `brew install terraform`)
* You have installed `packer` if you're gonna build your own custom AMI used in the examples.

1. In the `main.tf` file, replace `public_key` with your public key. This is used for SSH logins.
```
resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+A1zey3kk7XI48LQqguIdEtUk2FvSlPA0U2q25OORSXd6OUoUYNFTfaZ5EsFqpW7kH2/tlwolaqbPvsh3ASFY2Y8AIVrXonkIDY3XpSLdb12ijLcg9XNAMrBnN6OZ9arY5b/0gS9+o7ebhMnV4+6HA5m7jzz5a2o/SH5f6v5EjngX19Hqbvpa1/vzVSO+gQK3ERflPLGhnZdoy+OwnAyjkaKMwbOilXzYJrUDPj9PXP52p474LZHGeSGgcx0HIGyp58d4Lp41J/8bPoEW0hhyzuTZlQdg+z0KnvSF1INcrQqQTEfTn5mETuhdECw+v8qQNXmhjaMB+q8h6tI/LbLv jeck@blackpine.local"
}
```

2. Jump box and app nodes are using a custom AMI `ami-033661d1b9a6874e0` in ap-southeast-2 region. 
It is a Ubuntu-16.04 AMI with `nginx`. See `packer/ubuntu-16.04` to create your own and simply change
the AMI references.

3. Run Terraform!

Initialize Terraform
```
$ terraform init
```
Run terraform apply to provision the resources
```
$ terraform apply -auto-approve
```
Run terraform destroy to delete the resources
```
$ terraform destroy -auto-approve
```

Have fun!
