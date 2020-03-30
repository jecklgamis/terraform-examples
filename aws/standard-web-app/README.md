##  standard-web-app

## Getting Started

Requirements:
* Ensure you have AWS account (hopefully you're still on Free Tier) and properly configured

`~/.aws/config`:
```
[default]
region = ap-southeast-2
output = json
s3 =
    signature_version = s3v4
```

`~/.aws/credentials`:
```
[default]
region = ap-southeast-2
output = json
s3 =
    signature_version = s3v4
```


* Ensure you have Terraform installed

## Procedure
1. Go to `standard-web-app`
2. Initialize Ter 

This infrastructure code creates
* 1 VPC in ap-southeast-2 (Sydney)
* 2 public subnets (dmz-1,dmz-2) for frontend app, in two availability zones
* 2 private subnets (app-a, app-b) for frontend app, in two availability zones
* 1 jump box (bastion box) in public subnet 
* Creates SGs for web app, load balancer, and bastion traffic
* Creates ALB in public subnet
* Creates ALB in private subnet
* Creates ASG and launch config in public subnet
* Creates ASG and launch config in private subnet

### Procedures
* Replace region if you need to (defaults to `ap-southeast-2`)
* Replace this with your public key (`~/.ssh/id_rsa.pub`)
```
resource "aws_key_pair" "deployer" {
  region = "ap-southeast-2"0
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+A1zey3kk7XI48LQqguIdEtUk2FvSlPA0U2q25OORSXd6OUoUYNFTfaZ5EsFqpW7kH2/tlwolaqbPvsh3ASFY2Y8AIVrXonkIDY3XpSLdb12ijLcg9XNAMrBnN6OZ9arY5b/0gS9+o7ebhMnV4+6HA5m7jzz5a2o/SH5f6v5EjngX19Hqbvpa1/vzVSO+gQK3ERflPLGhnZdoy+OwnAyjkaKMwbOilXzYJrUDPj9PXP52p474LZHGeSGgcx0HIGyp58d4Lp41J/8bPoEW0hhyzuTZlQdg+z0KnvSF1INcrQqQTEfTn5mETuhdECw+v8qQNXmhjaMB+q8h6tI/LbLv jeck@blackpine.local"
}
```

### Testing

 
