provider "aws" {
  region = "ap-northeast-2"
}

# 보안적 요소 고려
# profile
# assume_role -> role_arn / session_name

/*
어떤 계정/리전에 배포할지 변수로 관리

로컬 WSL에서 aws configure --profile dev로 자격증명 사용
*/