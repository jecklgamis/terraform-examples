## Load Balanced ECS Application

This infrastructure code creates
* 1 VPC and 2 public subnets
* 1 Internet gateway
* Custom route table for the two public subnets
* Creates ECS cluster
* Creates ECS app task definition (Fargate type)
* Task definition uses nginx:latest container and uses 80:80 port mapping
* Creates ECS service 
* Creates ALB and Target Group and attached to the ECS service


  
 
