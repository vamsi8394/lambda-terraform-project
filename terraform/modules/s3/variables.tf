variable "main_bucket_name" {
  description = "Name of the main S3 bucket"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for storing access logs"
  type        = string
}

variable "folder_name" {
  description = "Name of the folder to create in the main bucket (must end with /)"
  type        = string
  default     = "my-application-folder/"
}

variable "lifecycle_rule_name" {
  description = "Name of the lifecycle rule"
  type        = string
  default     = "expire-all-objects-rule"
}

variable "expiration_days" {
  description = "Number of days after which objects will expire"
  type        = number
  default     = 90
}

variable "versioning_enabled" {
  description = "Enable versioning for the main bucket"
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

variable "log_prefix" {
  description = "Prefix for access logs"
  type        = string
  default     = "access-logs/"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
  }
}
