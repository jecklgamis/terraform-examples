## terraform-examples

Some working Terraform examples for provisioning AWS resources.

1. single-public -  single VPC with 1 public subnet
2. single-public-single-private - single VPC with 1 public and 1 private subnet
3. loadbalanced-ec2 -  auto scaled internet facing EC2 app
4. loadbalanced-ecs -  auto scaled internet facing ECS app
5. privatelink -  2 VPCs with VPC endpoint connection

## One-off Setup

* Create an AWS account. You will need a credit card and a mobile, confirm registration email to ensure setup complete.
* Download and Install awscli(v2): https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html
* Create a non-root user and download credentials and run `aws configure`

## Running
Ensure:
* You have configured your AWS credentials with appropriate permission to the AWS resources (EC2, ECS, IAM, VPC)
* You have Terraform installed, (Mac OSX: `brew install terraform` and `brew install ruby` if required)
* You have installed `packer` if you're gonna build your own custom AMI used in the examples.

1. In the `main.tf` file, replace `public_key` with your public key file location. This is used for SSH logins.
```
resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
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
