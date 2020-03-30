provider "aws" {
  profile = "default"
  region = "ap-southeast-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "single-public"
  }
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
  ami = "ami-0f355ac876f669b84"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [
    aws_security_group.web-sg.id
  ]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "web-server"
    BaseImageId = "ami-0f355ac876f669b84"
  }
}

resource "aws_eip" "elastic-ip" {
  instance = aws_instance.web-server.id
  vpc = true
  depends_on = [
    aws_internet_gateway.internet-gw]
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+A1zey3kk7XI48LQqguIdEtUk2FvSlPA0U2q25OORSXd6OUoUYNFTfaZ5EsFqpW7kH2/tlwolaqbPvsh3ASFY2Y8AIVrXonkIDY3XpSLdb12ijLcg9XNAMrBnN6OZ9arY5b/0gS9+o7ebhMnV4+6HA5m7jzz5a2o/SH5f6v5EjngX19Hqbvpa1/vzVSO+gQK3ERflPLGhnZdoy+OwnAyjkaKMwbOilXzYJrUDPj9PXP52p474LZHGeSGgcx0HIGyp58d4Lp41J/8bPoEW0hhyzuTZlQdg+z0KnvSF1INcrQqQTEfTn5mETuhdECw+v8qQNXmhjaMB+q8h6tI/LbLv jeck@blackpine.local"
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

data "aws_route_tables" "rts" {
  vpc_id = aws_vpc.main.id
}

output "route-tables" {
  value = data.aws_route_tables.rts
}

output "web-server-public-ip" {
  value = aws_instance.web-server.public_ip
}

output "connect-instruction" {
  value = "ssh -i  ~/.ssh/id_rsa ubuntu@${aws_instance.web-server.public_ip}"
}

output "test-curl-instruction" {
  value = "curl http://${aws_instance.web-server.public_ip}"
}



