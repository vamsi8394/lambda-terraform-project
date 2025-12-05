# Environment configuration
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "861276084741"
}

# S3 bucket configuration
variable "main_bucket_name" {
  description = "Name of the main S3 bucket for storing contracts"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for storing access logs"
  type        = string
}

variable "log_prefix" {
  description = "Prefix for S3 access logs"
  type        = string
  default     = "access-logs/"
}

# Jira configuration
variable "jira_base_url" {
  description = "Base URL for Jira API (e.g., https://yourcompany.atlassian.net)"
  type        = string
}

variable "jira_email" {
  description = "Email address for Jira API authentication"
  type        = string
  sensitive   = true
}

variable "jira_api_token" {
  description = "API token for Jira authentication"
  type        = string
  sensitive   = true
}

# Lambda configuration - Webhook Lambda
variable "webhook_lambda_memory" {
  description = "Memory size (MB) for the webhook Lambda function"
  type        = number
  default     = 512
}

variable "webhook_lambda_timeout" {
  description = "Timeout (seconds) for the webhook Lambda function"
  type        = number
  default     = 30
}

variable "webhook_lambda_log_retention" {
  description = "CloudWatch log retention days for webhook Lambda"
  type        = number
  default     = 7
}

# Lambda configuration - Extract Text Lambda
variable "extracttext_lambda_memory" {
  description = "Memory size (MB) for the extract text Lambda function"
  type        = number
  default     = 2048
}

variable "extracttext_lambda_timeout" {
  description = "Timeout (seconds) for the extract text Lambda function"
  type        = number
  default     = 300
}

variable "extracttext_lambda_log_retention" {
  description = "CloudWatch log retention days for extract text Lambda"
  type        = number
  default     = 7
}
