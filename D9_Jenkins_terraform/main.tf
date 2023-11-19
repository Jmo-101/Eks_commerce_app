# configure aws provider
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = "us-east-1"
    #profile = "Admin"
}

# Create VPC make sure to include a cidr range 
resource "aws_vpc" "dep9vpc" {
 cidr_block = "10.0.0.0/16"

 tags = {
   Name = "D9-Jenkins_VPC"
 }
}

# Creating Public Subnet 2 (us-east-1b)
resource "aws_subnet" "public_subnetb" {
 vpc_id     = aws_vpc.dep9vpc.id
 availability_zone = "us-east-1b"
 cidr_block = "10.0.1.0/24"
 map_public_ip_on_launch = true 
 tags = {
   Name = "PublicSubnet1b"
 }
}

# Creating Public Subnet 1 (us-east-1a)
resource "aws_subnet" "public_subneta" {
 vpc_id     = aws_vpc.dep9vpc.id
 availability_zone = "us-east-1a"
 cidr_block = "10.0.2.0/24"
 map_public_ip_on_launch = true 
 tags = {
   Name = "PublicSubnet1a"
 }
}

# Making an Internet Gateway
resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.dep9vpc.id
 
 tags = {
   Name = "D9-Jenkins_IG"
 }
}

# Creating Security Group to include ports 22, 8080, 8000 of ingress 
 resource "aws_security_group" "dep9sg" {
 name = "D9-Jenkins_SG"
 vpc_id = aws_vpc.dep9vpc.id

 ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

 }

  ingress {
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  
 }

 egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 tags = {
  "Name" : "D9-Jenkins_SG"
  "Terraform" : "true"
 }

}



#associating the default route table that Terraform will create with the internet gateway and everything that exists within the vpc 
resource "aws_default_route_table" "deproute9" {
  default_route_table_id = aws_vpc.dep9vpc.default_route_table_id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}



# Create Instance 1 (Jenkins)
resource "aws_instance" "instance1" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.medium"
  key_name               = "D9-keypair"
  subnet_id              = aws_subnet.public_subneta.id
  vpc_security_group_ids = [aws_security_group.dep9sg.id]
  user_data = "${file("jenkins.sh")}"
  
  
  tags = {
    "Name" : "D9-JenkinsManager"
  }
}

# Create Instance 2 (Kubernetes Agent)
resource "aws_instance" "instance2" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.medium"
  key_name               = "D9-keypair"
  subnet_id              = aws_subnet.public_subnetb.id
  vpc_security_group_ids = [aws_security_group.dep9sg.id]
  user_data = "${file("kubEKSctl.sh")}"
  
  tags = {
    "Name" : "D9-JAgent_Kubernetes"
  }
}

# Create Instance 3 (Docker Agent)
resource "aws_instance" "instance3" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.medium"
  key_name               = "D9-keypair"
  subnet_id              = aws_subnet.public_subnetb.id
  vpc_security_group_ids = [aws_security_group.dep9sg.id]
  user_data = "${file("docker.sh")}"

  tags = {
    "Name" : "D9-JAgent_Docker"
  }
}
