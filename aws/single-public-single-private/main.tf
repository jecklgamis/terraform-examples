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
    Name = "single-public-single-private"
  }
}

resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "internet-gw"
  }
}

resource "aws_eip" "nat-gw" {
  vpc = true
  depends_on = [
    aws_internet_gateway.internet-gw]
}

resource "aws_nat_gateway" "nat-gw-1" {
  allocation_id = aws_eip.nat-gw.id
  subnet_id = aws_subnet.public-subnet.id
}

resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_route" "r" {
  route_table_id = aws_vpc.main.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat-gw-1.id
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

resource "aws_security_group" "backend-sg" {
  name = "backend-sg"
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
    Name = "backend-sg"
  }
}

resource "aws_instance" "web-server" {
  ami = "ami-02d7e25c1cfdd5695"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [
    aws_security_group.web-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "web-server"
  }
}

resource "aws_instance" "backend-server" {
  ami = "ami-02d7e25c1cfdd5695"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private-subnet.id
  vpc_security_group_ids = [
    aws_security_group.backend-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "backend-server"
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
    cidr_block = "10.0.0.0/0"
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

output "web-server-public-ip" {
  value = aws_instance.web-server.public_ip
}

output "front-end-app-ssh" {
  value = "Connect to web server instance: ssh -i  ~/.id_rsa ubuntu@${aws_instance.web-server.public_dns}"
}

output "front-end-app-curl" {
  value = "Test web service endpoint: curl http://${aws_eip.elastic-ip}"
}

output "backend-app-ssh" {
  value = "Connect to backend instance: ssh -i  ~/.id_rsa ubuntu@${aws_instance.backend-server.public_dns}"
}



