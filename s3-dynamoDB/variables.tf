variable "state_bucket_name" {
  description = "Terraform state를 저장할 S3 버킷 이름. 전역 유일해야 한다"
  type        = string
}

variable "state_lock_table_name" {
  description = "state 잠금용 DynamoDB 테이블 이름"
  type        = string
  default     = "terraform-locks"
}
