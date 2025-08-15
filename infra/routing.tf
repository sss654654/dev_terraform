# NAT 게이트웨이 생성을 위한 EIP (Elastic IP) 할당
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
  tags = {
    Name = "dev-nat-gateway-eip"
  }
}

# NAT 게이트웨이 생성
resource "aws_nat_gateway" "dev_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "dev-nat-gateway"
  }
}

# 퍼블릭 라우팅 테이블
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-public-route-table"
  }
}

# 퍼블릭 라우팅 테이블에 인터넷 게이트웨이 라우팅 추가
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_igw.id
}

# 퍼블릭 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# gitlab용 테스트 퍼블릭 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "test_public_gitlab_subnet_association" {
  subnet_id      = aws_subnet.test_public_gitlab_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


# 프라이빗 라우팅 테이블
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-private-route-table"
  }
}

# EKS Fargate 프라이빗 서브넷 전용 라우팅 테이블
resource "aws_route_table" "eks_fargate_private_route_table" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-eks-fargate-private-route-table"
  }
}

# EKS Fargate 프라이빗 서브넷 전용 라우팅 테이블에 NAT 게이트웨이 라우팅 추가
resource "aws_route" "eks_fargate_nat_route" {
  route_table_id         = aws_route_table.eks_fargate_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.dev_nat_gateway.id
}

# EKS Fargate 프라이빗 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "eks_fargate_subnet_association" {
  subnet_id      = aws_subnet.eks_fargate_private_subnet.id
  route_table_id = aws_route_table.eks_fargate_private_route_table.id
}

# Gitlab 프라이빗 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "gitlab_subnet_association" {
  subnet_id      = aws_subnet.gitlab_private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# DB 프라이빗 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "db_subnet_association" {
  subnet_id      = aws_subnet.db_private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}