provider "aws" {
  profile = "default"
  region = "ap-southeast-2"
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+A1zey3kk7XI48LQqguIdEtUk2FvSlPA0U2q25OORSXd6OUoUYNFTfaZ5EsFqpW7kH2/tlwolaqbPvsh3ASFY2Y8AIVrXonkIDY3XpSLdb12ijLcg9XNAMrBnN6OZ9arY5b/0gS9+o7ebhMnV4+6HA5m7jzz5a2o/SH5f6v5EjngX19Hqbvpa1/vzVSO+gQK3ERflPLGhnZdoy+OwnAyjkaKMwbOilXzYJrUDPj9PXP52p474LZHGeSGgcx0HIGyp58d4Lp41J/8bPoEW0hhyzuTZlQdg+z0KnvSF1INcrQqQTEfTn5mETuhdECw+v8qQNXmhjaMB+q8h6tI/LbLv jeck@blackpine.local"
}

#***********************************************************************************************************************
# Main VPC
#***********************************************************************************************************************
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
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

resource "aws_subnet" "app-a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "app-a"
  }
}

resource "aws_subnet" "app-b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "app-b"
  }
}

resource "aws_security_group" "bastion-sg" {
  name = "bastion-sg"
  description = "Allow bastion traffic"
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
  description = "Allow app traffic"
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
  description = "Allow lb traffic"
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

resource "aws_security_group" "endpoint-sg" {
  name = "endpoint-sg"
  description = "Allow vpc endpoint traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
    Name = "endpoint-sg"
  }
}


resource "aws_route_table" "dmz" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }
  tags = {
    Name = "dmz"
  }
}

resource "aws_route_table_association" "add-dmz-1" {
  subnet_id = aws_subnet.dmz-1.id
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

resource "aws_instance" "backend-app-1" {
  ami = "ami-0f355ac876f669b84"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.app-a.id
  vpc_security_group_ids = [
    aws_security_group.webapp-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "backend-app-1"
  }
}

resource "aws_instance" "backend-app-2" {
  ami = "ami-0f355ac876f669b84"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.app-b.id
  vpc_security_group_ids = [
    aws_security_group.webapp-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "backend-app-2"
  }
}

resource "aws_lb" "backend-app-lb" {
  name = "backend-app-lb"
  internal = true
  load_balancer_type = "application"
  subnets = [
    aws_subnet.app-a.id,
    aws_subnet.app-b.id,
  ]
  security_groups = [
    aws_security_group.lb-sg.id]
  ip_address_type = "ipv4"
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "backend-target-group" {
  name = "backend-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
}

resource "aws_lb_listener" "backend-http-listener" {
  load_balancer_arn = aws_lb.backend-app-lb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.backend-target-group.arn
  }
}

resource "aws_lb_target_group_attachment" "attach-backend-1-to-lb" {
  target_group_arn = aws_lb_target_group.backend-target-group.arn
  target_id = aws_instance.backend-app-1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "attach-backend-2-to-lb" {
  target_group_arn = aws_lb_target_group.backend-target-group.arn
  target_id = aws_instance.backend-app-2.id
  port = 80
}

output "jump-box-1" {
  value = "Connect to jump box using : ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.jump-box-1.public_ip}"
}

#***********************************************************************************************************************
resource "aws_vpc_endpoint" "vpce-s3" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.ap-southeast-2.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "vpce-s3"
  }
  route_table_ids = [
    aws_vpc.main.default_route_table_id
  ]
}
resource "aws_vpc_endpoint" "vpce-to-vpc2-service" {
  vpc_id = aws_vpc.main.id
  service_name = aws_vpc_endpoint_service.vpc2-vpce-svc-1.service_name
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.endpoint-sg.id]
  tags = {
    Name = "vpce-to-vpc2-service"
  }
  subnet_ids = [
    aws_subnet.app-a.id,
    aws_subnet.app-b.id
  ]
}

########################################################################################################################
# Second VPC (Kanagawa)
#########################################################################################################################
resource "aws_vpc" "vpc2" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc2"
  }
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_internet_gateway" "vcp2-internet-gw" {
  vpc_id = aws_vpc.vpc2.id
  tags = {
    Name = "vcp2-internet-gw"
  }
}

resource "aws_subnet" "vpc2-dmz-1" {
  vpc_id = aws_vpc.vpc2.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "vpc2-dmz-1"
  }
}

resource "aws_route_table" "vpc2-dmz" {
  vpc_id = aws_vpc.vpc2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vcp2-internet-gw.id
  }
  tags = {
    Name = "vpc2-dmz"
  }
}

resource "aws_route_table_association" "add-vcp2-dmz-1" {
  subnet_id = aws_subnet.vpc2-dmz-1.id
  route_table_id = aws_route_table.vpc2-dmz.id
}

resource "aws_subnet" "vpc2-app-a" {
  vpc_id = aws_vpc.vpc2.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "vpc2-app-a"
  }
}

resource "aws_subnet" "vpc2-app-b" {
  vpc_id = aws_vpc.vpc2.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "vpc2-app-b"
  }
}

resource "aws_security_group" "vpc2-bastion-sg" {
  name = "vpc2-bastion-sg"
  description = "Allow bastion traffic"
  vpc_id = aws_vpc.vpc2.id
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
    Name = "vpc2-bastion-sg"
  }
}

resource "aws_security_group" "vpc2-webapp-sg" {
  name = "vpc2-webapp-sg"
  description = "Allow app traffic"
  vpc_id = aws_vpc.vpc2.id

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
    Name = "vpc2-webapp-sg"
  }
}

resource "aws_security_group" "vpc2-lb-sg" {
  name = "vpc2-lb-sg"
  description = "Allow lb traffic"
  vpc_id = aws_vpc.vpc2.id

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

resource "aws_instance" "vpc2-jump-box-1" {
  ami = "ami-0f355ac876f669b84"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.vpc2-dmz-1.id
  vpc_security_group_ids = [
    aws_security_group.vpc2-bastion-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "vpc2-jump-box-1"
  }
  associate_public_ip_address = true
}

resource "aws_instance" "vpc2-backend-app-1" {
  ami = "ami-0f355ac876f669b84"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.vpc2-app-a.id
  vpc_security_group_ids = [
    aws_security_group.vpc2-webapp-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "vpc2-backend-app-1"
  }
}

resource "aws_instance" "vpc2-backend-app-2" {
  ami = "ami-0f355ac876f669b84"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.vpc2-app-b.id
  vpc_security_group_ids = [
    aws_security_group.vpc2-webapp-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "vpc2-backend-app-2"
  }
}

resource "aws_lb" "vpc2-nlb-1" {
  name = "vpc2-nlb-1"
  load_balancer_type = "network"
  internal = true
  subnets = [
    aws_subnet.vpc2-app-a.id,
    aws_subnet.vpc2-app-b.id
  ]
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "vpc2-backend-svc-tg" {
  name = "vpc2-backend-svc-tg"
  port = 80
  protocol = "TCP"
  vpc_id = aws_vpc.vpc2.id
}

resource "aws_lb_listener" "vpc2-backend-svc-listener" {
  load_balancer_arn = aws_lb.vpc2-nlb-1.arn
  port = "80"
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.vpc2-backend-svc-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "vpc-2-attach-backend-app-1-to-tg" {
  target_group_arn = aws_lb_target_group.vpc2-backend-svc-tg.arn
  target_id = aws_instance.vpc2-backend-app-1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "vpc-2-attach-backend-app-2-to-tg" {
  target_group_arn = aws_lb_target_group.vpc2-backend-svc-tg.arn
  target_id = aws_instance.vpc2-backend-app-2.id
  port = 80
}

resource "aws_vpc_endpoint_service" "vpc2-vpce-svc-1" {
  acceptance_required = false
  network_load_balancer_arns = [
    aws_lb.vpc2-nlb-1.arn]
  tags = {
    Name = "vpc2-vpce-svc-1"
  }
}


output "vpc2-jump-box-1" {
  value = "Connect to jump box using : ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.vpc2-jump-box-1.public_ip}"
}

