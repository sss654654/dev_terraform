variable "admin_cidr_blocks" {
  description = "Client VPN 엔드포인트에 443으로 접근을 허용할 CIDR. 관리자 공인 IP라 코드에 두지 않는다"
  type        = list(string)
}

variable "key_name" {
  description = "EC2에 연결할 기존 키 페어 이름"
  type        = string
}

variable "client_vpn_server_certificate_arn" {
  description = "Client VPN 서버 인증서 ARN. 계정 ID가 들어 있어 코드에 두지 않는다"
  type        = string
  default     = ""
}

variable "client_vpn_root_certificate_arn" {
  description = "Client VPN 클라이언트 루트 인증서 체인 ARN"
  type        = string
  default     = ""
}
