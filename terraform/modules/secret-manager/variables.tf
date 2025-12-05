variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = ""
}

variable "secret_value" {
  description = "The secret value (can be JSON encoded string or plain string)"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the secret"
  type        = map(string)
  default     = {}
}

variable "recovery_window_days" {
  description = "Number of days to retain the secret before permanent deletion"
  type        = number
  default     = 7
}
