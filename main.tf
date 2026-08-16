terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "mcserver" {
  ami           = "ami-091124c3965bce679"
  instance_type = var.ec2_type
  primary_network_interface {
    network_interface_id = aws_network_interface.mcserver-netif0.id
  }
  key_name   = aws_key_pair.mcserversshk.key_name
  depends_on = [aws_internet_gateway.mcvpcigw]
  tags = {
    Name = "MinecraftServer"
  }
  user_data_base64 = var.ec2_user_data_b64
}

resource "aws_key_pair" "mcserversshk" {
  key_name   = "minecraft-server-key"
  public_key = var.ssh_public_key
}

resource "aws_vpc" "mcvpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "Minecraft VPC"
  }
}

resource "aws_internet_gateway" "mcvpcigw" {
  vpc_id = aws_vpc.mcvpc.id
  tags = {
    Name = "Minecraft VPC Gateway"
  }
}

resource "aws_route_table" "mcvpcrt" {
  vpc_id = aws_vpc.mcvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mcvpcigw.id
  }
  tags = {
    Name = "Minecraft VPC Route Table"
  }
}

resource "aws_main_route_table_association" "mcvcrtma" {
  vpc_id         = aws_vpc.mcvpc.id
  route_table_id = aws_route_table.mcvpcrt.id
}

resource "aws_subnet" "mcvpcs0" {
  vpc_id                  = aws_vpc.mcvpc.id
  cidr_block              = "10.0.0.0/28"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Minecraft Server VPC Subnet 0"
  }
}

resource "aws_network_interface" "mcserver-netif0" {
  subnet_id       = aws_subnet.mcvpcs0.id
  private_ip      = "10.0.0.2"
  security_groups = [aws_security_group.mcserversg.id]
  tags = {
    Name = "Minecraft Server Network Interface"
  }
}

resource "aws_security_group" "mcserversg" {
  name        = "minecraft-secgrp"
  description = "Allow SSH and Minecraft game traffic (port 25565) to all ports"
  vpc_id      = aws_vpc.mcvpc.id
  tags = {
    name = "minecraft-secgrp"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mcserversg.id
  cidr_ipv4         = var.ssh_allowed_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_mc_tcp" {
  security_group_id = aws_security_group.mcserversg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 25565
  ip_protocol       = "tcp"
  to_port           = 25565
}

resource "aws_vpc_security_group_ingress_rule" "allow_mc_udp" {
  security_group_id = aws_security_group.mcserversg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 25565
  ip_protocol       = "udp"
  to_port           = 25565
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.mcserversg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}