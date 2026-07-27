/*
원격 state 설정.

backend 블록은 변수를 쓸 수 없어서, 저장소마다 달라지는 값(버킷·잠금 테이블)은
파일 밖으로 뺀다. init 할 때 넘긴다.

  terraform init -backend-config=backend.hcl

backend.hcl은 커밋하지 않는다(backend.hcl.example 참고).
여기서 참조하는 S3 버킷과 DynamoDB 테이블은 s3-dynamoDB/에서 먼저 만들어야 한다.
같은 스택으로는 만들 수 없다 — state 저장소 자신이 state에 들어가면 순환이 된다.
*/
terraform {
  backend "s3" {
    key     = "global/s3/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }
}
