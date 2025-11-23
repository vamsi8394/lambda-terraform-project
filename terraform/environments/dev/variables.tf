variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

# Jira Webhook Lambda Variables
variable "jira_email" {
  description = "Jira user email for basic auth"
  type        = string
  sensitive   = true
}

variable "jira_api_token" {
  description = "Jira API token for basic auth"
  type        = string
  sensitive   = true
}

variable "jira_base_url" {
  description = "Base URL for Jira instance"
  type        = string
}


variable "main_bucket_name" {
  description = "Name of the main S3 bucket"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for storing access logs"
  type        = string
}

variable "log_prefix" {
  description = "Prefix for access logs"
  type        = string
  default     = "access-logs/"
}

variable "secrets_arn" {
  description = "Secrets Manager ARN for Jira credentials"
  type        = string
}

# Lambda Configuration
variable "webhook_lambda_memory" {
  description = "Memory allocation for webhook Lambda"
  type        = number
  default     = 512
}

variable "webhook_lambda_timeout" {
  description = "Timeout for webhook Lambda in seconds"
  type        = number
  default     = 90
}

variable "webhook_lambda_log_retention" {
  description = "CloudWatch log retention days for webhook Lambda"
  type        = number
  default     = 7
}

variable "extracttext_lambda_memory" {
  description = "Memory allocation for extract text Lambda"
  type        = number
  default     = 512
}

variable "extracttext_lambda_timeout" {
  description = "Timeout for extract text Lambda in seconds"
  type        = number
  default     = 180
}

variable "extracttext_lambda_log_retention" {
  description = "CloudWatch log retention days for extract text Lambda"
  type        = number
  default     = 7
}
