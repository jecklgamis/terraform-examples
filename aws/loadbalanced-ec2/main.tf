provider "aws" {
  profile = "default"
  region = "ap-southeast-2"
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+A1zey3kk7XI48LQqguIdEtUk2FvSlPA0U2q25OORSXd6OUoUYNFTfaZ5EsFqpW7kH2/tlwolaqbPvsh3ASFY2Y8AIVrXonkIDY3XpSLdb12ijLcg9XNAMrBnN6OZ9arY5b/0gS9+o7ebhMnV4+6HA5m7jzz5a2o/SH5f6v5EjngX19Hqbvpa1/vzVSO+gQK3ERflPLGhnZdoy+OwnAyjkaKMwbOilXzYJrUDPj9PXP52p474LZHGeSGgcx0HIGyp58d4Lp41J/8bPoEW0hhyzuTZlQdg+z0KnvSF1INcrQqQTEfTn5mETuhdECw+v8qQNXmhjaMB+q8h6tI/LbLv jeck@blackpine.local"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "loadbalanced-ec2"
  }
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "internet-gw"
  }
}

resource "aws_subnet" "dmz-1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "dmz-1"
  }
}

resource "aws_subnet" "dmz-2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "dmz-2"
  }
}

resource "aws_security_group" "bastion-sg" {
  name = "bastion-sg"
  description = "Allow all traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags = {
    Name = "bastion-sg"
  }
}


resource "aws_security_group" "webapp-sg" {
  name = "webapp-sg"
  description = "Allow all traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags = {
    Name = "webapp-sg"
  }
}


resource "aws_security_group" "lb-sg" {
  name = "lb-sg"
  description = "Allow all traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags = {
    Name = "lb-sg"
  }
}

resource "aws_route_table" "dmz" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "10.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }
  tags = {
    Name = "dmz"
  }
}

## associate dmz with the custom route table
resource "aws_route_table_association" "add-dmz-1" {
  subnet_id = aws_subnet.dmz-1.id
  route_table_id = aws_route_table.dmz.id
}

resource "aws_route_table_association" "add-dmz-2" {
  subnet_id = aws_subnet.dmz-2.id
  route_table_id = aws_route_table.dmz.id
}

resource "aws_instance" "jump-box-1" {
  ami = "ami-0f355ac876f669b84"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.dmz-1.id
  vpc_security_group_ids = [
    aws_security_group.bastion-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "jump-box-1"
  }
  associate_public_ip_address = true
}

resource "aws_lb" "frontend-app-lb" {
  name = "frontend-app-lb"
  internal = false
  load_balancer_type = "application"
  subnets = [
    aws_subnet.dmz-1.id,
    aws_subnet.dmz-2.id
  ]
  security_groups = [
    aws_security_group.lb-sg.id]
  ip_address_type = "ipv4"
  enable_cross_zone_load_balancing = true
}


resource "aws_lb_target_group" "frontend-target-group" {
  name = "frontend-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
}

resource "aws_lb_listener" "frontend-http-listener" {
  load_balancer_arn = aws_lb.frontend-app-lb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend-target-group.arn
  }
}

# create launch config for autoscaling group for frontend apps
resource "aws_launch_configuration" "frontend-launch-config" {
  name = "frontend-launch-config"
  image_id = "ami-0f355ac876f669b84"
  instance_type = "t2.micro"
  security_groups = [
    aws_security_group.webapp-sg.id]
}

resource "aws_autoscaling_group" "frontend-asg" {
  name = "frontend-asg"
  launch_configuration = aws_launch_configuration.frontend-launch-config.id
  min_size = 1
  max_size = 4
  lifecycle {
    create_before_destroy = true
  }
  vpc_zone_identifier = [
    aws_subnet.dmz-1.id,
    aws_subnet.dmz-2.id]
  target_group_arns = [
    aws_lb_target_group.frontend-target-group.arn
  ]
}

resource "aws_autoscaling_policy" "frontend-asg-target-tracking" {
  name = "frontend-asg-target-tracking"
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.frontend-asg.name

  target_tracking_configuration {
    disable_scale_in = true
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 5
  }
}

output "jump-box-1" {
  value = "Connect to jump box using : ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.jump-box-1.public_ip}"
}

output "frontend-app-lb" {
  value = "Test ALB using: curl ${aws_lb.frontend-app-lb.dns_name}"
}


