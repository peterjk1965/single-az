# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  region                   = "us-east-2" # Replace with your desired AWS region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform"
}

# 1. Create a custom VPC
resource "aws_vpc" "pjk-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "pjk-vpc"
  }
}

# 2. Create and attach the internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.pjk-vpc.id

  tags = {
    Name = "pjk-vpc-igw"
  }
}

# 3. Create public and private subnets
resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.pjk-vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = var.az-1
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.pjk-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.az-1

  tags = {
    Name = "private-subnet"
  }
}

# 4. Create a NAT gateway
resource "aws_eip" "elastic-ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 5. Create custom route tables
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.pjk-vpc.id

  route {
    cidr_block = var.all-ipv4
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.pjk-vpc.id

  route {
    cidr_block = var.all-ipv4
    gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# 6. Subnet association with route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt.id
}

# 7. Create security groups
resource "aws_security_group" "allow" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.pjk-vpc.id

  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.all-ipv4]
  }

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.all-ipv4]
  }

  ingress {
    description = "SSH into instance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.all-ipv4]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all-ipv4]
  }

  tags = {
    Name = "allow-tls"
  }
}

resource "aws_security_group" "only-ssh-bastion" {
  name        = "ssh-bastion"
  description = "Allow SSH for bastion"
  vpc_id      = aws_vpc.pjk-vpc.id

  ingress {
    description = "SSH into instance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my-ipv4]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all-ipv4]
  }

  tags = {
    Name = "ssh-bastion"
  }
}

resource "aws_security_group" "private-allow" {
  name        = "ssh-private"
  description = "Allow SSH from bastion"
  vpc_id      = aws_vpc.pjk-vpc.id

  ingress {
    description     = "SSH into private instance"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.only-ssh-bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all-ipv4]
  }

  tags = {
    Name = "private-allow-tls"
  }
}

