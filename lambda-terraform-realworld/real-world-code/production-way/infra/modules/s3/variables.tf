variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}
variable "kms_key_arn" {
  description = "KMS Key ID for bucket encryption"
  type        = string
}

variable "if_versioning" {
  description = "Flag to enable bucket versioning"
  type        = bool
  default     = false

}
variable "if_encrypted" {
  description = "Flag to enable bucket encryption"
  type        = bool
  default     = false
}
variable "log_bucket" {
  description = "S3 bucket for logging"
  type        = string
}