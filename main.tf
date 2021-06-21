terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
  profile = "default"
  shared_credentials_file = "$HOME/.aws/credentials"
}

#Creating Custom VPC
resource "aws_vpc" "devvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "Dev_VPC"
  }
}

#Creating Internet Gateway
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.devvpc.id
  tags = {
    Name = "Dev IGW"
  }
}

resource "aws_eip" "nat_eip" {
  vpc      = true
}

#Creating Nat Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.devsubnet_public.id
  tags = {
    Name = "gw NAT"
  }
  depends_on = [aws_internet_gateway.dev_igw]
}

#Adding new Route Table for public routing
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }
  tags = {
    Name = "Public RT"
  }
}

#Adding new Route Table for private routing
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.devvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "Private RT"
  }
}

#Public Subnet
resource "aws_subnet" "devsubnet_public" {
  vpc_id     = aws_vpc.devvpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Dev_Subnet Public"
  }
}
#Private Subnet
resource "aws_subnet" "devsubnet_private" {
  vpc_id     = aws_vpc.devvpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "Dev_Subnet Private"
  }
}

resource "aws_route" "route_public" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.dev_igw.id
  depends_on                = [aws_route_table.public_rt]
}

resource "aws_route_table_association" "sub_pub" {
  subnet_id      = aws_subnet.devsubnet_public.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "sub_priv" {
  subnet_id      = aws_subnet.devsubnet_private.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id = aws_vpc.devvpc.id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_security_group" "nfs" {
  name        = "nfs"
  description = "Open requierd ports for the NFS daemon"
  vpc_id = aws_vpc.devvpc.id
  ingress {
    description      = "NFS"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "NFS-sg"
  }
}

resource "aws_security_group" "master_node_sg" {
  name        = "master_node_sg"
  description = "Open requierd ports for the K8 Master Mode"
  vpc_id = aws_vpc.devvpc.id
  ingress {
    description      = "Kubernetes API server"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "etcd server client API"
    from_port        = 2379
    to_port          = 2380
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "kubelet API"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "kube-scheduler"
    from_port        = 10251
    to_port          = 10251
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "kube-controller-manager"
    from_port        = 10252
    to_port          = 10252
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "K8_Master_SG"
  }
}

resource "aws_security_group" "worker_node_sg" {
  name        = "worker_node_sg"
  description = "Open requierd ports for the K8 Worker(s) Mode"
  vpc_id = aws_vpc.devvpc.id
  ingress {
    description      = "kubelet API"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "NodePort Services"
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "K8_Worker_SG"
  }
}

resource "aws_security_group" "testport" {
  name        = "testport"
  description = "Testing"
  vpc_id = aws_vpc.devvpc.id
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Testing Port"
  }
}

resource "aws_instance" "master_ec2" {
  subnet_id = aws_subnet.devsubnet_public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.nfs.id, aws_security_group.master_node_sg.id, aws_security_group.testport.id]
  #associate_public_ip_address = true
  ami = "ami-0bad4a5e987bdebde"
  instance_type = "t3.small"
  key_name = "autokey"
  #security_groups = ["allow_ssh","nfs","master_node_sg","testport"]
  tags = {
    "Name" = "Master_Node"
  }
}

resource "aws_instance" "worker_ec2" {
  subnet_id = aws_subnet.devsubnet_private.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.nfs.id, aws_security_group.worker_node_sg.id, aws_security_group.testport.id]
  ami = "ami-0bad4a5e987bdebde"
  instance_type = "t3.small"
  count = 2
  key_name = "autokey"
  #security_groups = ["allow_ssh","nfs","worker_node_sg","testport"]
  tags = {
    "Name" = "Worker_Node"
  }
}

resource "aws_instance" "nfs-server" {
  subnet_id = aws_subnet.devsubnet_private.id  
  vpc_security_group_ids = [aws_security_group.allow_ssh.id,aws_security_group.nfs.id]
  ami = "ami-0bad4a5e987bdebde"
  instance_type = "t2.micro"
  key_name = "autokey"
  #security_groups = ["nfs","allow_ssh"]
  tags = {
    "Name" = "NFS-server"
  }
}

resource "aws_key_pair" "autokey" {
  key_name   = "autokey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKyziClfNHD7mlSxcrAb4WjOftS1kw54VaDkLttsLM2zXORCUUEFKC8nmM5KE3hNILnbfRdqL5Cvd4DK5yjQlhRHSiWN6m2jxMootUnM1RKCigYv0t7FiHo+AGe85RuCPmvVd85g+aszzbeIZuvP6Lm+imCh6EfDFC8Xnjsni20B8ZAVPMANCe0xcW+IjR4D1/rellEyyhD49fnJws6BYXAEoZuZeRaMqVsETCKyJisYWTEziJQeWGn5LMtl7ZLE0+OomxE2UFwx95luqIXUkT8Z1OZfKxtUn/N+uUrwTJQgkPjq8FvV9xeutIgoqA2EEUvqVKdkrfGo4mvnT63VspDQ8qD/Hx3khq8ggxz5gG19UH1WGhnzGCghEDJVyYlEgeI9NF7Ct1epxKBq4v7fvpBkYREe0AfrqTrV7KH/7N+Pxt4vRzNd6TVvNJwoGvGMYnKOOd18VTxsHaHGyPCX8G13DOwUwvbcWLdO8GzT5pMgRDFwBeQtgjbb+AY8SdDWU= user@DESKTOP-4T3B48Q"
}

output "master_public_ip" {
  description = "Public IP address of Master Node"
  value       = aws_instance.master_ec2.public_ip
}

output "woker1_private_ip" {
  description = "Private IP address of Worker Node1"
  value       = aws_instance.worker_ec2[0].private_ip
}

output "woker2_private_ip" {
  description = "Private IP address of Worker Node2"
  value       = aws_instance.worker_ec2[1].private_ip
}

output "nfs-server_private_ip" {
  description = "Private IP address of Worker Node2"
  value       = aws_instance.nfs-server.private_ip
}
