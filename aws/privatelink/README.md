## private link

This infrastructure code creates:
* 2 VPCs, main and vpc2
* main has
  - 1 public and 2 private subnets
  - 1 jump box
  - 2 backend EC2 nodes behind ALB
  - VPC endpoint to S3 (Gateway type)
  - VPC endpoint to VPC endpoint service in vpc2 (Interface type)
  - Security groups for LB, nodes, and endpoints
* vpc2 has
  - 1 public and 2 private subnets
  - 1 jump box
  - 2 backend EC2 nodes behind NLB
  - VPC endpoint service 
  - Security groups for LB, nodes, and endpoints
      
 
