# dev_terraform — 개발 환경 AWS 네트워크 (Terraform)

CGV 예매 시스템 팀 프로젝트에서 개발계 AWS 네트워크 계층을 Terraform으로 구성한 코드다.
VPC·서브넷·라우팅·보안그룹·VPC 엔드포인트·ECR·GitLab EC2와 원격 state 저장소를 다룬다.

## 담당 범위

| 구성 | 이 저장소 |
|---|---|
| VPC · 서브넷 · IGW · NAT Gateway · 라우팅 | O |
| 보안그룹 | O |
| VPC 엔드포인트 (ECR api/dkr, S3) | O |
| ECR 리포지토리 | O |
| GitLab EC2 · EIP | O |
| 원격 state (S3 + DynamoDB) | O |
| EKS 클러스터 | X — 팀원이 `eksctl`로 생성 |
| RDS · ElastiCache | X — 서브넷과 보안그룹만 여기서 준비 |
| GitLab CI 파이프라인 · ArgoCD | X — 팀원 담당 |

## 파일 구조

```
infra/
  VPC-Subnet.tf     VPC, 서브넷, Internet Gateway
  routing.tf        라우트 테이블 4개, NAT Gateway, EIP
  sg.tf             보안그룹 5개
  endpoints.tf      VPC 엔드포인트 5개
  ec2_instance.tf   GitLab EC2, EIP
  ecr.tf            ECR 리포지토리
  client_vpn.tf     Client VPN 구성 (현재 주석 처리 — 아래 "GitLab 접근" 참고)
  backend.tf        원격 state 참조 (partial config)
  providers.tf      AWS 프로바이더
  versions.tf       Terraform · 프로바이더 버전 제약
  variables.tf      민감값 변수 선언

s3-dynamoDB/
  s3-dynamoDB.tf    state 버킷과 잠금 테이블 (최초 1회 별도 apply)
```

## 네트워크 구성

```
VPC  10.0.0.0/16   ap-northeast-2

Public                                          라우트
  10.0.1.0/24    public-subnet-a       NAT GW   → IGW
  10.0.2.0/24    test-public-gitlab    EC2      → IGW

Private
  10.0.40.0/24   gitlab                         인터넷 라우트 없음
  10.0.20.0/24   db                    RDS·Redis 배치용, 인터넷 라우트 없음
  10.0.30.0/24   eks-fargate-a                  → NAT(2a)
  10.0.31.0/24   eks-fargate-c                  → NAT(2a)

VPC Endpoint
  ecr.dkr / ecr.api    gitlab 서브넷용, eks 서브넷용 각각 (Interface)
  s3                   eks 라우트 테이블에 연결 (Gateway)
```

## 설계 결정

### VPC 엔드포인트로 ECR 트래픽을 NAT에서 뺀다

컨테이너 이미지 pull이 NAT Gateway를 지나면 시간당 요금과 별개로 데이터 처리 요금이 붙는다.
이미지 레이어는 용량이 커서 이 비용이 누적된다. ECR 인터페이스 엔드포인트를 두면 그 트래픽이
NAT를 거치지 않고 VPC 안에서 끝난다.

엔드포인트가 두 종류인 것은 ECR이 두 API로 나뉘어 있기 때문이다.

- `ecr.api` — 인증 토큰 발급, 리포지토리 조회
- `ecr.dkr` — 이미지 레이어 실제 전송

하나만 만들면 인증은 되는데 pull이 NAT로 나가거나 그 반대가 된다.

GitLab 서브넷과 EKS 서브넷에 각각 따로 만든 것은 인터페이스 엔드포인트가 **서브넷 단위로 ENI를
만들기** 때문이다. 하나만 두면 다른 서브넷의 트래픽이 그 ENI까지 우회한다.
S3는 Gateway 타입이라 ENI 없이 라우트 테이블 항목으로 붙는다.

### NAT Gateway를 한 개만 둔다

2a에만 NAT Gateway를 만들고, 2c의 EKS 서브넷 라우트도 그 NAT를 가리킨다.

- 얻는 것: NAT Gateway 시간당 요금이 절반
- 잃는 것: 2a 가용영역 장애 시 2c 워크로드의 아웃바운드도 끊긴다
- 개발 환경이라 가용성보다 비용을 택했다. 운영 환경이면 AZ마다 두어야 한다

### GitLab 접근 — 프라이빗 + VPN에서 퍼블릭으로 전환했다

처음에는 GitLab EC2를 인터넷 라우트가 없는 `gitlab` 서브넷에 두고, Client VPN 엔드포인트를
그 서브넷에 연결해 인증서 인증으로만 접근하도록 구성했다.

개발 단계에서는 접근 빈도가 높아 매번 VPN을 거치는 비용이 커서, dev 환경은 퍼블릭 서브넷의
EC2로 전환했다. 프라이빗 인스턴스와 Client VPN 구성은 지우지 않고 `client_vpn.tf`와
`ec2_instance.tf`에 주석으로 남겨뒀다. `gitlab` 서브넷과 `client_vpn_sg`는 그래서 만들어지지만
지금은 비어 있다.

현재 상태의 한계는 분명하다 — 퍼블릭 서브넷의 EC2에 붙은 `test_public_gitlab_sg`는 인바운드가
전부 `0.0.0.0/0`이다. 접근 편의를 위해 열어둔 것이고, 운영 환경이면 주석 처리된 프라이빗 +
Client VPN 구성으로 돌아가야 한다.

### state를 S3 + DynamoDB로 분리한다

`s3-dynamoDB/`는 state 버킷과 잠금 테이블만 만든다. `infra/`와 디렉토리를 나눈 이유는
**state 저장소 자신이 state에 들어가면 순환이 생기기** 때문이다. 최초 1회 여기서 apply한 뒤
`infra/`가 그 버킷을 백엔드로 참조한다.

- 버킷: 서버 사이드 암호화, 퍼블릭 액세스 차단
- 잠금 테이블: `LockID` 해시 키, 온디맨드 과금

버킷·테이블 이름은 `backend` 블록에 직접 쓰지 않는다. backend 블록은 변수를 받지 못해서
partial configuration으로 분리했다.

## 실행 순서

```bash
# 1. state 저장소 (최초 1회)
cd s3-dynamoDB
cp terraform.tfvars.example terraform.tfvars   # 버킷 이름을 채운다
terraform init && terraform apply

# 2. 네트워크
cd ../infra
cp backend.hcl.example backend.hcl             # 위에서 만든 버킷·테이블 이름
cp terraform.tfvars.example terraform.tfvars   # 관리자 IP, 키 페어 이름
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

`terraform.tfvars`와 `backend.hcl`은 커밋하지 않는다. 관리자 공인 IP와 계정 정보가 들어간다.
