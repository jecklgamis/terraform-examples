provider "aws" {
  profile = "default"
  region = "ap-southeast-2"
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "single-public"
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
resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_security_group" "web-sg" {
  name = "web-sg"
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
    description = "HTTPS"
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
    Name = "web-sg"
  }
}

resource "aws_instance" "web-server" {
  ami = "ami-033661d1b9a6874e0"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [
    aws_security_group.web-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "web-server"
    BaseImageId = "ami-033661d1b9a6874e0"
  }
}

resource "aws_eip" "elastic-ip" {
  instance = aws_instance.web-server.id
  vpc = true
  depends_on = [
    aws_internet_gateway.internet-gw]
}

resource "aws_route_table" "route-1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }

  tags = {
    Name = "route-1"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.route-1.id
}

output "ssh-connection" {
  value = "Connect to web server instance using: ssh -i  ~/.ssh/id_rsa ubuntu@${aws_eip.elastic-ip.public_dns}"
}

output "test-endpoint" {
  value = "Test endpoint using:  curl http://${aws_eip.elastic-ip.public_dns}"
}



