## loadbalanced-ec2

This infrastructure code creates:
* 1 VPC and 2 public subnets
* 1 ALB, 2 EC2 nodes running nginx, CPU auto scaling policy
* 1 jump box node
* Security groups