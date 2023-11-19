# configure aws provider
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = "us-east-1"
    #profile = "Admin"
}


#CREATING D9 VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = "172.28.0.0/16"
  
  tags = {
    "Name" = "D9-VPC"
  }
}


#CREATE PUBLIC SUBNET A
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "172.28.0.0/18"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "D9-Public1a"
  }
}


#CREATE PRIVATE SUBNET A
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "172.28.64.0/18"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "D9-Private1a"
  }
}

#CREATING PUBLIC SUBNET B
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "172.28.128.0/18"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "D9-Public1b"
  }
}

#CREATING PRIVATE SUBNET B
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "172.28.192.0/18"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "D9-Private1b"
  }
}


#ASSOCIATING PUB + PRIV A SUBNETS TO ROUTE TABLES
resource "aws_route_table_association" "public_a_subnet" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a_subnet" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}


#ASSOCIATING PUB + PRIV B SUBNETS TO ROUTE TABLES
resource "aws_route_table_association" "public_b_subnet" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_b_subnet" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}


#ASSIGNING ELASTIC IP
resource "aws_eip" "elastic-ip" {
  domain = "vpc"
}


#CREATING IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
}


#CREATING NATGW
resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public_a.id
  allocation_id = aws_eip.elastic-ip.id
}

#CREATING PUBLIC ROUTE TABLE 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app_vpc.id
}

#CREATING PRIVATE ROUTE TABLE
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app_vpc.id
}


#ASSOCIATING IGW WITH PUBLIC ROUTE TABLE
resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}


#ASSOCIATING NATGW WITH PRIVATE ROUTE TABLE
resource "aws_route" "private_ngw" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}
