variable "state_machine_name" {
  description = "Name of the Step Functions state machine"
  type        = string
}

variable "definition" {
  description = "Amazon States Language definition of the state machine"
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role for Step Functions execution (if not provided, one will be created)"
  type        = string
  default     = ""
}

variable "state_machine_type" {
  description = "Type of state machine (STANDARD or EXPRESS)"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "EXPRESS"], var.state_machine_type)
    error_message = "State machine type must be either STANDARD or EXPRESS."
  }
}

variable "logging_level" {
  description = "Logging level (ALL, ERROR, FATAL, OFF)"
  type        = string
  default     = "ERROR"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "create_role" {
  description = "Whether to create an IAM role for the state machine"
  type        = bool
  default     = true
}

variable "lambda_function_arns" {
  description = "List of Lambda function ARNs that the state machine will invoke"
  type        = list(string)
  default     = []
}

variable "eventbridge_connection_arns" {
  description = "List of EventBridge connection ARNs that the state machine will use"
  type        = list(string)
  default     = []
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for contract files (used in IAM policy)"
  type        = string
  default     = ""
}

variable "jira_base_url" {
  description = "Base URL for Jira instance (used in IAM policy condition)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
