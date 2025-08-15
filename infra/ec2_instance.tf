/*
# public_subnet에 생성할 bastion_host용 인스턴스
resource "aws_instance" "bastion_host" {
  ami           = "ami-0897f20d7e803af8f" # Gitlab과 동일한 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id # 퍼블릭 서브넷에 생성
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true # 퍼블릭 IP 주소 할당

  tags = {
    Name = "dev-bastion-host"
  }
}

# Gitlab EC2 인스턴스 생성
resource "aws_instance" "gitlab_instance" {
  ami           = "ami-0897f20d7e803af8f" 
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.gitlab_private_subnet.id # 프라이빗 서브넷에 생성
  vpc_security_group_ids =  [aws_security_group.gitlab_sg.id]
  associate_public_ip_address = false # 프라이빗 서브넷에 생성되므로 퍼블릭 IP는 필요 없음
  tags = {
    Name = "dev-gitlab-instance"
  }
}
*/


# gitlab용 임시 pulic_subnet
resource "aws_instance" "public_gitlab" {
  ami           = "ami-0897f20d7e803af8f" # linux
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.test_public_gitlab_subnet.id # 퍼블릭 서브넷에 생성
  vpc_security_group_ids = [aws_security_group.test_public_gitlab_sg.id]
  associate_public_ip_address = true # 퍼블릭 IP 주소 할당

  tags = {
    Name = "test-public-gitlab-host"
  }
}