# dev_terraform-main\infra\VPC-Subnet.tf

# VPC 생성
resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "dev-vpc"
    "kubernetes.io/cluster/dev-eks-cluster" = "shared"
  }
}

# 인터넷 게이트웨이 (IGW) 생성 및 VPC에 연결
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-igw"
    "kubernetes.io/cluster/dev-eks-cluster" = "shared"
  }
}

# NAT용 퍼블릭 서브넷 생성
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true # EC2 생성 시 퍼블릭 IP 자동 할당
  tags = {
    Name = "dev-public-subnet"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/dev-eks-cluster" = "owned"
  }
}


# gitlab용 임시 퍼블릭 서브넷 생성
resource "aws_subnet" "test_public_gitlab_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true # EC2 생성 시 퍼블릭 IP 자동 할당
  tags = {
    Name = "test-public-gitlab-subnet"
  }
}



# DB Private Subnet
resource "aws_subnet" "db_private_subnet" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "dev-db-private-subnet"
    "kubernetes.io/cluster/dev-eks-cluster" = "shared"
  }
}

# EKS Fargate Private Subnet
resource "aws_subnet" "eks_fargate_private_subnet" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "dev-eks-fargate-private-subnet"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/dev-eks-cluster" = "owned"
  }
}


# Gitlab Private Subnet
resource "aws_subnet" "gitlab_private_subnet" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "dev-gitlab-private-subnet"
  }
}