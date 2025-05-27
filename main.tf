### **Terraform Template (VPC + EC2 + IAM)**
#### **main.tf**
### This Terraform script creates a VPC with subnets and provisions an EC2 instance with reasonable IAM permissions.

### ```hcl
provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "allow_https" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0037200d7bbced3e7"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_https.id]

  tags = {
    Name = "WebServer"
  }

  iam_instance_profile = aws_iam_instance_profile.web_profile.name
}

resource "aws_iam_role" "web_role" {
  name = "WebServerRole"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": { "Service": "ec2.amazonaws.com" },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "web_profile" {
  name = "WebInstanceProfile"
  role = aws_iam_role.web_role.name
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "web_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "web_eip_assoc" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web_eip.id
}